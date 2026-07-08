function tests = test_constraints
    %TEST_CONSTRAINTS dplmi direct coefficient-wise assembly.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so constraint IDs stay local to this suite.
    yalmip("clear");
end

function testComparisonDefaults(testCase)
    % dpvar comparisons should return inspectable dplmi wrappers.
    P = dpvar(2, {[0 0.5 1]}, "symmetric");

    Cneg = P <= 0;
    Cpos = P >= 0;

    testCase.verifyClass(Cneg, "dplmi");
    testCase.verifyClass(Cpos, "dplmi");
    verifyDefaults(testCase, Cneg);
    verifyDefaults(testCase, Cpos);
    testCase.verifyEqual(numel(Cneg.Constraints), 4);
    testCase.verifyEqual(numel(Cpos.Constraints), 4);
    verifyConstraintCells(testCase, Cneg);
    verifyConstraintCells(testCase, Cpos);
end

function testRateRowsAllConstrained(testCase)
    % rhodiff stores one row per rate vertex; dplmi constrains every row.
    P = dpvar(2, {[0 1 2]}, "symmetric", RateBounds=[-1 1]);
    D = rhodiff(P);

    C = D <= 0;

    testCase.verifyClass(C, "dplmi");
    testCase.verifyEqual(numel(C.Constraints), 4);
    verifyConstraintCells(testCase, C);
end

function testTensorRateRowsAllConstrained(testCase)
    % Tensor rate bounds create one constraint per rate vertex and coefficient.
    rb = [-1 1; -2 2];
    P = dpvar(2, {[0 1], [0 1]}, "symmetric", RateBounds=rb);
    D = rhodiff(P);

    C = D <= 0;

    testCase.verifyEqual(size(D.coeffs([1 1])), [4 4]);
    testCase.verifyEqual(numel(C.Constraints), 16);
    verifyConstraintCells(testCase, C);
end

function testComposedResidualWithRhodiff(testCase)
    % Residual assembly should constrain every elevated derivative rate row.
    P = dpvar(2, {[0 1]}, "symmetric");
    A = dpmat({[0 1]}, {[-1 0; 0 -2], [-2 0; 0 -3]}, Degree=1);
    R = A' * P + P * A + rhodiff(P, [-1 1]);

    C = R <= 0;

    testCase.verifyTrue(R.HasRateDependence);
    testCase.verifyEqual(R.RateBounds, [-1 1]);
    testCase.verifyEqual(R.Degree, 2);
    testCase.verifyEqual(size(R.coeffs(1)), [2 3]);
    testCase.verifyEqual(numel(C.Constraints), 6);
    verifyConstraintCells(testCase, C);
end

function testRejectsNonSquareAndNonSymmetric(testCase)
    % Semidefinite constraints need square symmetric coefficient matrices.
    V = dpvar(2, 1, {[0 1]}, "full");
    F = dpvar(2, {[0 1]}, "full");

    testCase.verifyError(@() V <= 0, "dplmi:InvalidMatrixSize");
    testCase.verifyError(@() F <= 0, "dplmi:NonSymmetricExpression");
end

function testAllowsSymmetricExpression(testCase)
    % A full variable can still form an LMI after explicit symmetrization.
    P = dpvar(2, {[0 1]}, "full");

    C = (P + P') <= 0;

    testCase.verifyClass(C, "dplmi");
    testCase.verifyEqual(numel(C.Constraints), 2);
    verifyConstraintCells(testCase, C);
end

function testReservedOptions(testCase)
    P = dpvar(2, {[0 1]}, "symmetric");

    C = dplmi(P, "<=", relaxLemma=false, UsePolya=false, PolyaDegree=0);

    verifyDefaults(testCase, C);
    testCase.verifyError(@() dplmi(P, "<=", relaxLemma=true), ...
        "dplmi:UnsupportedRelaxLemma");
    testCase.verifyError(@() dplmi(P, "<=", UsePolya=true), ...
        "dplmi:UnsupportedPolya");
    testCase.verifyError(@() dplmi(P, "<=", PolyaDegree=1), ...
        "dplmi:UnsupportedPolya");
end

function testToYalmip(testCase)
    P = dpvar(2, {[0 1]}, "symmetric");
    C = P <= 0;

    F = toYalmip(C);

    testCase.verifyTrue(isa(F, "lmi") || isa(F, "constraint"));
end

function verifyDefaults(testCase, C)
    testCase.verifyFalse(C.RelaxLemma);
    testCase.verifyFalse(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, 0);
end

function verifyConstraintCells(testCase, C)
    testCase.verifyTrue(iscell(C.Constraints));
    testCase.verifySize(C.Constraints, [numel(C.Constraints), 1]);
    for k = 1:numel(C.Constraints)
        testCase.verifyTrue(isa(C.Constraints{k}, "constraint"));
    end
end
