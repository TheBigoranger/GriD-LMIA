function tests = test_to_yalmip
    % Behavioral regressions for pdlmi.to_yalmip.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so constraint IDs stay local to this suite.
    yalmip("clear");
end

function test_export_after_replacement_keeps_saved_list_independent(testCase)
    % Exported lists retain their original cones after another family is built.
    P = pdvar(2, [0 1 4], Degree=2, RateBounds=[2 2]);
    original = usePutinar(rhodiff(P) <= 0, 1);
    saved = toYalmip(original);
    replacement = original.usePolya(2);
    veriConCol(testCase, toYalmip(original), saved);
    veriConCol(testCase, toYalmip(replacement), sequCon(replacement.Constraints));
    controls = [P.coeffs(1), P.coeffs(2)];
    testCase.verifyEmpty(intersect( ...
        setdiff(getvariables(saved), getvariables([controls{:}])), ...
        getvariables(toYalmip(replacement))));
end

function test_stored_constraints(testCase)
    P = pdvar(2, {[0 1]}, "symmetric");
    C = P <= 0;

    F = toYalmip(C);

    testCase.verifyTrue(isa(F, "lmi") || isa(F, "constraint"));
end

function test_solver_facing_shot_concatenation_match_previous(testCase)
    % Solver-facing one-shot concatenation must match the previous loop.
    P = pdvar(2, {[0 1]}, "symmetric");
    direct = P >= 0;
    polya = direct.usePolya(1);
    equality = pdvar(2, {[0 1]}, "full") == 0;
    rectangular = pdvar(2, 1, {[0 1]}, "full");
    entrywise = consWitSinWar(testCase, @() rectangular >= 0);

    X = sdpvar(2);
    mixedExpr = internalPdvar({[0 1]}, [2 2], 1, ...
        {{zeros(2), X}}, [], "test-mixed-export");
    mixed = mixedExpr >= 0;

    wrappers = {direct, polya, equality, entrywise, mixed};
    for k = 1:numel(wrappers)
        actual = toYalmip(wrappers{k});
        reference = sequCon(wrappers{k}.Constraints);
        veriConCol(testCase, actual, reference);
    end
end

function out = sequCon(entries)
    % Reproduce the pre-optimization export loop as an independent oracle.
    state = warning;
    cleanup = onCleanup(@() warning(state)); %#ok<NASGU>
    warning("off", "all");
    out = [];
    for k = 1:numel(entries)
        out = [out, entries{k}]; %#ok<AGROW>
    end
end

function veriConCol(testCase, actual, reference)
    % Compare ordering, cone/equality type, variables, bases, and PSD blocks.
    testCase.verifyEqual(length(actual), length(reference));
    for k = 1:length(actual)
        testCase.verifyEqual(is(actual(k), "equality"), ...
            is(reference(k), "equality"));
        testCase.verifyEqual(is(actual(k), "sdp"), is(reference(k), "sdp"));
        testCase.verifyEqual(getvariables(actual(k)), ...
            getvariables(reference(k)));
        actualExpr = sdpvar(actual(k));
        referenceExpr = sdpvar(reference(k));
        testCase.verifySize(actualExpr, size(referenceExpr));
        testCase.verifyEqual(full(getbase(actualExpr)), ...
            full(getbase(referenceExpr)), AbsTol=0);
    end

    [actualModel, referenceModel] = exportSedumi(actual, reference);
    testCase.verifyEqual(actualModel.K.f, referenceModel.K.f);
    testCase.verifyEqual(actualModel.K.l, referenceModel.K.l);
    testCase.verifyEqual(actualModel.K.s, referenceModel.K.s);
end

function out = consWitSinWar(testCase, fun)
    % Capture the successful wrapper and assert one emitted dispatch warning.
    lastwarn("");
    txt = evalc('out = fun();');
    [~, warnId] = lastwarn;
    testCase.verifyEqual(string(warnId), "pdlmi:ElementwiseInequality");
    testCase.verifyEqual(count(string(txt), ...
        "The residual is non-square or has a non-Hermitian coefficient"), 1);
end

function obj = internalPdvar(grid, matrixSize, degree, vals, rb, summary)
    % Build targeted coefficient trees that public continuous allocation cannot express.
    init = struct( ...
        "PdvarInternal", true, ...
        "Grid", {grid}, ...
        "MatrixSize", matrixSize, ...
        "Degree", degree, ...
        "LocalValues", {vals}, ...
        "IsContinuous", false, ...
        "ContainsDecision", any(cellfun(@(x) isa(x, "sdpvar"), flatten(vals))), ...
        "RateBounds", rb, ...
        "SourceSummary", summary);
    obj = pdvar(init);
end

function [actualModel, referenceModel] = exportSedumi(actual, reference)
    % MATLAB also ships an export function, so temporarily prioritize YALMIP.
    originalPath = path;
    cleanup = onCleanup(@() restorePath(originalPath)); %#ok<NASGU>
    addpath(fileparts(which("yalmip")), "-begin");
    clear export
    settings = sdpsettings;
    settings.solver = 'sedumi';
    settings.verbose = 0;
    actualModel = export(actual, [], settings);
    referenceModel = export(reference, [], settings);
    clear export
end

function out = flatten(vals)
    % Return nested coefficient payloads as a flat cell for fixture metadata.
    out = {};
    for k = 1:numel(vals)
        if iscell(vals{k})
            out = [out, flatten(vals{k})]; %#ok<AGROW>
        else
            out{end + 1} = vals{k}; %#ok<AGROW>
        end
    end
end

function restorePath(originalPath)
    path(originalPath);
    clear export
end
