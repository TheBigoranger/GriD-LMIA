function tests = test_concatenation
    % Behavioral regressions for pdlmi.concatenation.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so constraint IDs stay local to this suite.
    yalmip("clear");
end

function test_raw_yalmip_constraints_dispatch_pdlmi_both(testCase)
    % Raw YALMIP constraints dispatch through pdlmi in both operand orders.
    P = pdvar(1, {[0 1]});
    C = P >= 0;
    x = sdpvar(1);
    raw = x >= 0;
    exported = toYalmip(C);

    actual = {[C, raw], [raw, C], [C; raw], [raw; C]};
    reference = {[exported, raw], [raw, exported], ...
        [exported; raw], [raw; exported]};
    for k = 1:numel(actual)
        veriConCat(testCase, actual{k}, reference{k});
    end
end

function test_existing_yalmip_lists_composable_or_pdlmi(testCase)
    % Existing YALMIP lists remain composable before or after a pdlmi wrapper.
    P = pdvar(1, {[0 1]});
    C = P >= 0;
    x = sdpvar(1);
    list = [x >= 0, x <= 1];
    exported = toYalmip(C);

    actual = {[C, list], [list, C], [C; list], [list; C]};
    reference = {[exported, list], [list, exported], ...
        [exported; list], [list; exported]};
    for k = 1:numel(actual)
        veriConCat(testCase, actual{k}, reference{k});
    end
end

function test_each_wrapper_exported_independently_yalmip_merges(testCase)
    % Each wrapper is exported independently before YALMIP merges the lists.
    P = pdvar(1, {[0 1]});
    Q = pdvar(1, {[0 1]});
    lower = P >= 0;
    upper = Q <= 0;
    lowerExport = toYalmip(lower);
    upperExport = toYalmip(upper);

    veriConCat(testCase, [lower, upper], [lowerExport, upperExport]);
    veriConCat(testCase, [lower; upper], [lowerExport; upperExport]);
end

function test_identity_equality_contributes_same_empty_list(testCase)
    % An identity equality contributes the same empty list as toYalmip.
    P = pdvar(1, {[0 1]});
    identity = P == P;
    x = sdpvar(1);
    raw = x >= 0;

    veriConCat(testCase, [identity, raw], [toYalmip(identity), raw]);
    testCase.verifyEmpty([identity, identity]);
end

function test_logical_certificates_undeclared_operand_classes(testCase)
    % Logical certificates and undeclared operand classes are rejected locally.
    P = pdvar(1, {[0 1]});
    C = P >= 0;
    x = sdpvar(1);
    raw = x >= 0;
    known = pdmat([0 1], {1, 2}, Degree=1) >= 0;
    array = cat(2, C, C);
    errId = "pdlmi:InvalidConcatenation";

    testCase.verifyError(@() horzcat(known, raw), errId);
    testCase.verifyError(@() horzcat(raw, known), errId);
    testCase.verifyError(@() vertcat(known, raw), errId);
    testCase.verifyError(@() horzcat(C, true), errId);
    testCase.verifyError(@() horzcat(1, C), errId);
    testCase.verifyError(@() vertcat(C, false), errId);
    testCase.verifyError(@() horzcat(array, raw), errId);
end

function veriConCat(testCase, actual, reference)
    % Concatenation is a terminal conversion to a YALMIP constraint list.
    testCase.verifyTrue(isa(actual, "constraint") || isa(actual, "lmi"));
    veriConCol(testCase, actual, reference);
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

function restorePath(originalPath)
    path(originalPath);
    clear export
end
