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

function testRejectsNonSquareAndNonSymmetric(testCase)
    % Semidefinite constraints need square symmetric coefficient matrices.
    V = pdvar(2, 1, {[0 1]}, "full");
    F = pdvar(2, {[0 1]}, "full");

    testCase.verifyError(@() V <= 0, "pdlmi:InvalidMatrixSize");
    testCase.verifyError(@() F <= 0, "pdlmi:NonSymmetricExpression");
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
    P = pdvar(1, grid, Degree=1, RateBounds=[-1 1; -2 2]);

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

function verifyDefaults(testCase, C)
    testCase.verifyFalse(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, 0);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, 0);
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, 0);
end

function verifyPolya(testCase, C, degree, count)
    testCase.verifyTrue(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, degree);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, 0);
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, 0);
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

function verifyConstraintCells(testCase, C)
    testCase.verifyTrue(iscell(C.Constraints));
    testCase.verifySize(C.Constraints, [numel(C.Constraints), 1]);
    for k = 1:numel(C.Constraints)
        testCase.verifyTrue(isa(C.Constraints{k}, "constraint"));
    end
end
