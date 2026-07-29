function tests = test_constraints
    %TEST_CONSTRAINTS pdlmi direct coefficient-wise assembly.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so constraint IDs stay local to this suite.
    yalmip("clear");
end

function testComparisonDefaults(testCase)
    % pdvar comparisons should return inspectable pdlmi wrappers.
    P = pdvar(2, {[0 0.5 1]}, "symmetric");

    Cneg = P <= 0;
    Cpos = P >= 0;

    testCase.verifyClass(Cneg, "pdlmi");
    testCase.verifyClass(Cpos, "pdlmi");
    verifyDefaults(testCase, Cneg);
    verifyDefaults(testCase, Cpos);
    testCase.verifyEqual(numel(Cneg.Constraints), 4);
    testCase.verifyEqual(numel(Cpos.Constraints), 4);
    testCase.verifyTrue(isequal(Cneg.Residual, P));
    testCase.verifyTrue(isequal(Cpos.Residual, P));
    testCase.verifyEqual(Cneg.Relation, "<=");
    testCase.verifyEqual(Cpos.Relation, ">=");
    verifyConstraintCells(testCase, Cneg);
    verifyConstraintCells(testCase, Cpos);
end

function testRateRowsAllConstrained(testCase)
    % rhodiff stores one row per rate vertex; pdlmi constrains every row.
    P = pdvar(2, {[0 1 2]}, "symmetric", RateBounds=[-1 1]);
    D = rhodiff(P);

    C = D <= 0;

    testCase.verifyClass(C, "pdlmi");
    testCase.verifyEqual(numel(C.Constraints), 4);
    verifyConstraintCells(testCase, C);
end

function testTensorRateRowsAllConstrained(testCase)
    % Tensor rate bounds create one constraint per rate vertex and coefficient.
    rb = [-1 1; -2 2];
    P = pdvar(2, {[0 1], [0 1]}, "symmetric", RateBounds=rb);
    D = rhodiff(P);

    C = D <= 0;

    testCase.verifyEqual(size(D.coeffs([1 1])), [4 4]);
    testCase.verifyEqual(numel(C.Constraints), 16);
    verifyConstraintCells(testCase, C);
end

function testComposedResidualWithRhodiff(testCase)
    % Residual assembly should constrain every elevated derivative rate row.
    P = pdvar(2, {[0 1]}, "symmetric");
    A = pdmat({[0 1]}, {[-1 0; 0 -2], [-2 0; 0 -3]}, Degree=1);
    R = A' * P + P * A + rhodiff(P, [-1 1]);

    C = R <= 0;

    testCase.verifyTrue(R.HasRateDependence);
    testCase.verifyEqual(R.RateBounds, [-1 1]);
    testCase.verifyEqual(R.Degree, 2);
    testCase.verifyEqual(size(R.coeffs(1)), [2 3]);
    testCase.verifyEqual(numel(C.Constraints), 6);
    verifyConstraintCells(testCase, C);
end

function testHighDegreeResidualConstraintCount(testCase)
    % Direct assembly constrains every rate row of a cubic residual.
    P = pdvar(2, {[0 1]}, "symmetric", Degree=2);
    A = pdmat({[0 1]}, {[-1 0; 0 -2], [-2 0; 0 -3]}, Degree=1);
    R = A' * P + P * A + rhodiff(P, [-1 1]);

    C = R <= 0;

    testCase.verifyEqual(R.Degree, 3);
    testCase.verifyEqual(size(R.coeffs(1)), [2 4]);
    testCase.verifyEqual(numel(C.Constraints), 8);
    verifyConstraintCells(testCase, C);
end

function testEntrywiseDispatchAndTolerance(testCase)
    % Rectangular and structurally full square residuals use vector inequalities.
    rectangular = pdvar(3, 2, {[0 1]}, "full", Degree=0);
    rect = constructWithSingleWarning(testCase, @() rectangular >= 0);
    testCase.verifyEqual(numel(rect.Constraints), 1);
    verifyVectorConstraints(testCase, rect, 6);

    fullSquare = pdvar(2, {[0 1]}, "full", Degree=0);
    square = constructWithSingleWarning(testCase, @() fullSquare <= 0);
    fullCoeffs = fullSquare.coeffs(1);
    assign(fullCoeffs{1}, [-1 -2; -3 -4]);
    testCase.verifyGreaterThan(check(square.Constraints{1}), 0);
    verifyVectorConstraints(testCase, square, 4);

    symmetric = pdvar(2, {[0 1]}, "symmetric");
    testCase.verifyWarningFree(@() symmetric >= 0);
    symmetricLmi = symmetric >= 0;
    symmetricMeta = struct(symmetricLmi.Constraints{1});
    testCase.verifySize(symmetricMeta.List{1}, [2 2]);

    % The numeric tolerance is inclusive at exactly 1e-10.
    atTol = internalPdvar({[0 1]}, [2 2], 0, ...
        {{[0 1e-10; 0 0]}}, false, [], "test-at-tolerance");
    aboveTol = internalPdvar({[0 1]}, [2 2], 0, ...
        {{[0 1.0001e-10; 0 0]}}, false, [], "test-above-tolerance");
    testCase.verifyWarningFree(@() pdlmi(atTol, ">="));
    constructWithSingleWarning(testCase, @() pdlmi(aboveTol, ">="));
end

function testGlobalEntrywiseScanAcrossCellsAndRateRows(testCase)
    % A later offending coefficient changes every constraint in the wrapper.
    first = sdpvar(2, 2, 'symmetric');
    later = sdpvar(2, 2, 'full');
    acrossCells = internalPdvar({[0 1 2]}, [2 2], 0, ...
        {{first}, {later}}, false, [], "test-later-cell");
    cellwise = constructWithSingleWarning(testCase, @() acrossCells >= 0);
    assign(first, [1 2; 2 1]);
    assign(later, [1 2; 3 4]);

    testCase.verifyEqual(numel(cellwise.Constraints), 2);
    testCase.verifyGreaterThan(check(cellwise.Constraints{1}), 0, ...
        "The earlier indefinite coefficient must be constrained entry-wise.");
    verifyVectorConstraints(testCase, cellwise, 4);

    earlyRow = sdpvar(2, 2, 'symmetric');
    lateRow = sdpvar(2, 2, 'full');
    acrossRows = internalPdvar({[0 1]}, [2 2], 0, ...
        {{earlyRow; lateRow}}, true, [-1 1], "test-later-rate-row");
    ratewise = constructWithSingleWarning(testCase, @() acrossRows >= 0);
    assign(earlyRow, [1 2; 2 1]);
    assign(lateRow, [1 2; 3 4]);

    testCase.verifyEqual(numel(ratewise.Constraints), 2);
    testCase.verifyGreaterThan(check(ratewise.Constraints{1}), 0);
    verifyVectorConstraints(testCase, ratewise, 4);
end

function testEntrywiseDirectPolyaAndFailureOrdering(testCase)
    % Direct and elevated paths retain every cell, entry, and derivative row.
    V = pdvar(3, 2, {[0 1 2]}, "full", Degree=1);
    direct = constructWithSingleWarning(testCase, @() V >= 0);
    polya = constructWithSingleWarning(testCase, @() direct.applyPolya(2));
    D = rhodiff(V, [-1 1]);
    rate = constructWithSingleWarning(testCase, @() D <= 0);
    ratePolya = constructWithSingleWarning(testCase, @() rate.applyPolya());

    testCase.verifyEqual(numel(direct.Constraints), 2 * 2);
    testCase.verifyEqual(numel(polya.Constraints), 2 * 4);
    testCase.verifyEqual(size(D.coeffs(1)), [2 1]);
    testCase.verifyEqual(numel(rate.Constraints), 2 * 2);
    testCase.verifyEqual(numel(ratePolya.Constraints), 2 * 2 * 2);
    verifyVectorConstraints(testCase, direct, 6);
    verifyVectorConstraints(testCase, polya, 6);
    verifyVectorConstraints(testCase, rate, 6);
    verifyVectorConstraints(testCase, ratePolya, 6);

    % Option validation precedes classification, so failed construction is silent.
    lastwarn("");
    testCase.verifyError(@() pdlmi(V, ">=", ...
        UsePutinar=true, PutinarOrder=-1), "pdlmi:InvalidPutinarOrder");
    [~, warnId] = lastwarn;
    testCase.verifyEmpty(warnId);
end

function testAllowsSymmetricExpression(testCase)
    % A full variable can still form an LMI after explicit symmetrization.
    P = pdvar(2, {[0 1]}, "full");

    C = (P + P') <= 0;

    testCase.verifyClass(C, "pdlmi");
    testCase.verifyEqual(numel(C.Constraints), 2);
    verifyConstraintCells(testCase, C);
end

function testPolyaConstructorForms(testCase)
    % Bare flags and Name=Value forms select the same elevation semantics.
    P = pdvar(2, {[0 1]}, "symmetric");

    bare = pdlmi(P, "<=", "UsePolya");
    named = pdlmi(P, "<=", UsePolya=true);
    mixed = pdlmi(P, "<=", "UsePolya", PolyaDegree=2);
    paired = pdlmi(P, "<=", "UsePolya", true, "PolyaDegree", 2);
    zero = pdlmi(P, "<=", UsePolya=true, PolyaDegree=0);

    verifyPolya(testCase, bare, 1, 3);
    verifyPolya(testCase, named, 1, 3);
    verifyPolya(testCase, mixed, 2, 4);
    verifyPolya(testCase, paired, 2, 4);
    verifyPolya(testCase, zero, 0, 2);
    testCase.verifyWarningFree(@() pdlmi(P, "<=", UsePolya=true));
end

function testImplicitPolyaWarnings(testCase)
    % Supplying only the degree is accepted but must make the implicit mode visible.
    P = pdvar(1, {[0 1]});
    warnId = "pdlmi:ImplicitUsePolya";

    testCase.verifyWarning(@() pdlmi(P, "<=", PolyaDegree=2), warnId);
    testCase.verifyWarning(@() pdlmi(P, "<=", "PolyaDegree", 2), warnId);
    testCase.verifyWarning(@() pdlmi(P, "<=", PolyaDegree=0), warnId);

    named = callWarningOff(@() pdlmi(P, "<=", PolyaDegree=2), warnId);
    paired = callWarningOff(@() pdlmi(P, "<=", "PolyaDegree", 2), warnId);
    zero = callWarningOff(@() pdlmi(P, "<=", PolyaDegree=0), warnId);
    verifyPolya(testCase, named, 2, 4);
    verifyPolya(testCase, paired, 2, 4);
    verifyPolya(testCase, zero, 0, 2);
end

function testPolyaOptionInteractions(testCase)
    P = pdvar(2, {[0 1]}, "symmetric");

    direct = pdlmi(P, "<=", UsePolya=false, PolyaDegree=0);

    verifyDefaults(testCase, direct);
    testCase.verifyEqual(numel(direct.Constraints), 2);
    testCase.verifyError(@() pdlmi(P, "<=", ...
        UsePolya=false, PolyaDegree=1), ...
        "pdlmi:ConflictingPolyaOptions");
end

function testRemovedApiIsUnavailable(testCase)
    % Keep the retired names out of source text while guarding the API boundary.
    P = pdvar(1, {[0 1]}, Degree=1);
    C = P >= 0;
    oldOption = "Use" + "Relax" + "Lemma";
    oldMethod = "apply" + "Relax" + "Lemma";

    testCase.verifyError(@() pdlmi(P, "<=", oldOption, true), ...
        "pdlmi:UnknownOption");
    testCase.verifyFalse(isprop(C, oldOption));
    testCase.verifyFalse(any(string(methods(C)) == oldMethod));
end


function testPolyaTensorAndRateConstraintCounts(testCase)
    % Counts include every cell, elevated tensor label, and derivative rate row.
    grid = {[0 1 2], [10 20]};
    P = pdvar(1, grid, Degree=[1 1], RateBounds=[-1 1; -2 2]);

    tensor = pdlmi(P, ">=", "UsePolya", PolyaDegree=2);
    D = rhodiff(P);
    rate = pdlmi(D, "<=", "UsePolya");

    testCase.verifyEqual(tensor.Relation, ">=");
    testCase.verifyEqual(numel(tensor.Constraints), 2 * 1 * 4 ^ 2);
    testCase.verifyEqual(size(D.coeffs([1 1])), [4 4]);
    testCase.verifyEqual(numel(rate.Constraints), 2 * 4 * 3 ^ 2);
    verifyConstraintCells(testCase, tensor);
    verifyConstraintCells(testCase, rate);
end

function testApplyPolyaRebuildsFromStoredResidual(testCase)
    % Reapplying a degree replaces the selection rather than compounding it.
    P = pdvar(1, {[0 1]}, Degree=1);
    direct = P >= 0;

    one = direct.applyPolya();
    two = one.applyPolya(2);
    zero = two.applyPolya(0);

    verifyDefaults(testCase, direct);
    verifyPolya(testCase, one, 1, 3);
    verifyPolya(testCase, two, 2, 4);
    verifyPolya(testCase, zero, 0, 2);
    testCase.verifyEqual(numel(one.Constraints), 3);
    testCase.verifyTrue(isequal(two.Residual, P));
    testCase.verifyEqual(two.Relation, ">=");
end


function testPolyaCertificateAfterAssignment(testCase)
    % Elevation can certify a positive polynomial whose original middle coefficient is negative.
    P = pdvar(1, {[0 1]}, Degree=2);
    coeffs = P.coeffs(1);
    assigned = [1, -0.1, 1];
    for k = 1:numel(coeffs)
        assign(coeffs{k}, assigned(k));
    end

    direct = P >= 0;
    polya = direct.applyPolya(1);
    elevatedVals = P.elevVals(1);
    elevated = cellfun(@value, elevatedVals{1});
    directCheck = check(toYalmip(direct));
    polyaCheck = check(toYalmip(polya));

    testCase.verifyEqual(elevated, [1, 0.266666666666667, ...
        0.266666666666667, 1], AbsTol=1e-12);
    testCase.verifyLessThan(min(directCheck), 0);
    testCase.verifyGreaterThan(min(polyaCheck), 0);
end

function testRelationValidation(testCase)
    P = pdvar(1, {[0 1]});

    lower = pdlmi(P, '<=');
    upper = pdlmi(P, ">=");

    testCase.verifyEqual(lower.Relation, "<=");
    testCase.verifyEqual(upper.Relation, ">=");
    testCase.verifyError(@() pdlmi(P, char('<=', '>=')), ...
        "pdlmi:InvalidRelation");
    testCase.verifyError(@() pdlmi(P, "="), "pdlmi:InvalidRelation");
end

function testMalformedConstructorOptions(testCase)
    % Parser errors distinguish malformed syntax, duplicates, and unknown names.
    P = pdvar(1, {[0 1]});
    charMatrix = char('UsePolya', 'Unknown');

    testCase.verifyError(@() pdlmi(P, "<=", charMatrix), ...
        "pdlmi:InvalidOptions");
    testCase.verifyError(@() pdlmi(P, "<=", "Unknown", 1), ...
        "pdlmi:UnknownOption");
    testCase.verifyError(@() pdlmi(P, "<=", "UsePolya", "Unknown"), ...
        "pdlmi:UnknownOption");
    testCase.verifyError(@() pdlmi(P, "<=", ...
        "UsePolya", true, "UsePolya"), "pdlmi:DuplicateOption");
    testCase.verifyError(@() pdlmi(P, "<=", ...
        "PolyaDegree", "UsePolya"), "pdlmi:InvalidOptions");
end

function testPolyaDegreeValidation(testCase)
    P = pdvar(1, {[0 1]});
    C = P >= 0;
    badMethod = {-1, 0.5, Inf, NaN, "one", [1 2]};
    badConstructor = {-1, 0.5, Inf, NaN, [1 2]};

    for k = 1:numel(badMethod)
        testCase.verifyError(@() C.applyPolya(badMethod{k}), ...
            "pdlmi:InvalidPolyaDegree");
    end
    for k = 1:numel(badConstructor)
        testCase.verifyError(@() pdlmi(P, "<=", ...
            UsePolya=true, PolyaDegree=badConstructor{k}), ...
            "pdlmi:InvalidPolyaDegree");
    end
    testCase.verifyError(@() pdlmi(P, "<=", ...
        UsePolya=true, PolyaDegree="one"), "pdlmi:UnknownOption");
end

function testToYalmip(testCase)
    P = pdvar(2, {[0 1]}, "symmetric");
    C = P <= 0;

    F = toYalmip(C);

    testCase.verifyTrue(isa(F, "lmi") || isa(F, "constraint"));
end

function testAnisotropicDirectPolyaCountsAndReplacement(testCase)
    % Direction-wise increments use tensor counts and replace prior levels.
    grid = {[0 1], [10 20]};
    P = pdvar(1, grid, Degree=[1 3], RateBounds=[-1 2; -3 5]);
    direct = P >= 0;
    vector = direct.applyPolya([1 0]);
    bare = direct.applyPolya();
    replaced = vector.applyPolya([0 2]);

    verifyDefaults(testCase, direct);
    verifyPolya(testCase, vector, [1 0], prod([2 3] + 1));
    verifyPolya(testCase, bare, [1 1], prod([2 4] + 1));
    verifyPolya(testCase, replaced, [0 2], prod([1 5] + 1));
    testCase.verifyTrue(isequal(replaced.Residual, P));

    D = rhodiff(P);
    rateDirect = D <= 0;
    ratePolya = rateDirect.applyPolya([0 1]);
    testCase.verifyEqual(D.Degree, [1 3]);
    testCase.verifySize(D.coeffs([1 1]), [4 8]);
    testCase.verifyEqual(numel(rateDirect.Constraints), 4 * 8);
    testCase.verifyEqual(numel(ratePolya.Constraints), 4 * 2 * 5);
end

function testTensorPolyaDegreeValidation(testCase)
    % Tensor Pólya accepts ell-vectors and rejects every other shape.
    P = pdvar(1, {[0 1], [10 20]}, Degree=[1 2]);
    direct = P >= 0;
    accepted = direct.applyPolya([0; 2]);
    testCase.verifyEqual(accepted.PolyaDegree, [0 2]);

    bad = {[], [1 2 3], [1 2; 3 4], -1, 0.5, Inf, NaN};
    for k = 1:numel(bad)
        testCase.verifyError(@() direct.applyPolya(bad{k}), ...
            "pdlmi:InvalidPolyaDegree");
        testCase.verifyError(@() pdlmi(P, ">=", ...
            UsePolya=true, PolyaDegree=bad{k}), ...
            "pdlmi:InvalidPolyaDegree");
    end
    testCase.verifyError(@() direct.applyPolya("one"), ...
        "pdlmi:InvalidPolyaDegree");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        UsePolya=true, PolyaDegree="one"), "pdlmi:UnknownOption");
end

function testToYalmipOneShotMatchesSequential(testCase)
    % Solver-facing one-shot concatenation must match the previous loop.
    P = pdvar(2, {[0 1]}, "symmetric");
    direct = P >= 0;
    polya = direct.applyPolya(1);
    equality = pdvar(2, {[0 1]}, "full") == 0;
    rectangular = pdvar(2, 1, {[0 1]}, "full");
    entrywise = constructWithSingleWarning(testCase, @() rectangular >= 0);

    X = sdpvar(2);
    mixedExpr = internalPdvar({[0 1]}, [2 2], 1, ...
        {{zeros(2), X}}, false, [], "test-mixed-export");
    mixed = mixedExpr >= 0;

    wrappers = {direct, polya, equality, entrywise, mixed};
    for k = 1:numel(wrappers)
        actual = toYalmip(wrappers{k});
        reference = sequentialConstraints(wrappers{k}.Constraints);
        verifyConstraintCollection(testCase, actual, reference);
    end
end

function out = sequentialConstraints(entries)
    % Reproduce the pre-optimization export loop as an independent oracle.
    state = warning;
    cleanup = onCleanup(@() warning(state)); %#ok<NASGU>
    warning("off", "all");
    out = [];
    for k = 1:numel(entries)
        out = [out, entries{k}]; %#ok<AGROW>
    end
end

function verifyConstraintCollection(testCase, actual, reference)
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

function verifyDefaults(testCase, C)
    zero = zeros(1, C.Residual.npar());
    testCase.verifyFalse(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, zero);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, zero);
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, zero);
end

function verifyPolya(testCase, C, degree, count)
    degree = expandExpected(degree, C.Residual.npar());
    zero = zeros(1, C.Residual.npar());
    testCase.verifyTrue(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, degree);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, zero);
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, zero);
    testCase.verifyEqual(numel(C.Constraints), count);
    verifyConstraintCells(testCase, C);
end

function out = callWarningOff(fun, warnId)
    % Construct once without duplicating the warning already asserted above.
    state = warning("query", warnId);
    cleanup = onCleanup(@() warning(state.state, warnId)); %#ok<NASGU>
    warning("off", warnId);
    out = fun();
end

function value = expandExpected(value, nPar)
    % Expand scalar shorthand only in test expectations.
    if isscalar(value)
        value = repmat(value, 1, nPar);
    else
        value = reshape(value, 1, []);
    end
end

function out = constructWithSingleWarning(testCase, fun)
    % Capture the successful wrapper and assert one emitted dispatch warning.
    lastwarn("");
    txt = evalc('out = fun();');
    [~, warnId] = lastwarn;
    testCase.verifyEqual(string(warnId), "pdlmi:ElementwiseInequality");
    testCase.verifyEqual(count(string(txt), ...
        "The residual is non-square or has a non-Hermitian coefficient"), 1);
end

function verifyVectorConstraints(testCase, C, nEntry)
    % Entry-wise assembly stores one column-vector inequality per coefficient.
    for k = 1:numel(C.Constraints)
        metadata = struct(C.Constraints{k});
        testCase.verifySize(metadata.List{1}, [nEntry 1]);
    end
end

function obj = internalPdvar(grid, matrixSize, degree, vals, hasRate, rb, summary)
    % Build targeted coefficient trees that public continuous allocation cannot express.
    init = struct( ...
        "PdvarInternal", true, ...
        "Grid", {grid}, ...
        "MatrixSize", matrixSize, ...
        "Degree", degree, ...
        "LocalValues", {vals}, ...
        "IsContinuous", false, ...
        "ContainsDecision", any(cellfun(@(x) isa(x, "sdpvar"), flatten(vals))), ...
        "HasRateDependence", hasRate, ...
        "RateBounds", rb, ...
        "SourceSummary", summary);
    obj = pdvar(init);
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

function verifyConstraintCells(testCase, C)
    testCase.verifyTrue(iscell(C.Constraints));
    testCase.verifySize(C.Constraints, [numel(C.Constraints), 1]);
    for k = 1:numel(C.Constraints)
        testCase.verifyTrue(isa(C.Constraints{k}, "constraint"));
    end
end
