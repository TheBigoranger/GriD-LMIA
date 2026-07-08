function tests = test_affine_algebra
    %TEST_AFFINE_ALGEBRA Basic affine dpvar coefficient operations.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function testPlusMinusAndUnary(testCase)
    % Binary and unary operations should act coefficient-wise.
    P = dpvar(1, {[0 1]});
    Q = dpvar(1, {[0 1]});

    cp = P.coeffs(1);
    cq = Q.coeffs(1);
    S = P + Q;
    D = P - Q;
    N = -P;
    U = +P;

    verifyCoeffExpr(testCase, S.coeffs(1), {cp{1} + cq{1}, cp{2} + cq{2}});
    verifyCoeffExpr(testCase, D.coeffs(1), {cp{1} - cq{1}, cp{2} - cq{2}});
    verifyCoeffExpr(testCase, N.coeffs(1), {-cp{1}, -cp{2}});
    verifyCoeffExpr(testCase, U.coeffs(1), cp);
end

function testNumericPromotion(testCase)
    % Numeric constants become degree-0 data and are elevated to degree 1.
    P = dpvar(2, {[0 1]}, "full");
    cp = P.coeffs(1);
    S = P + 5;
    D = eye(2) - P;

    verifyCoeffExpr(testCase, S.coeffs(1), {cp{1} + 5 * ones(2), cp{2} + 5 * ones(2)});
    verifyCoeffExpr(testCase, D.coeffs(1), {eye(2) - cp{1}, eye(2) - cp{2}});
end

function testSdpvarPromotion(testCase)
    % Bare affine sdpvar matrices promote to constant coefficient data.
    P = dpvar(2, {[0 1]}, "full");
    X = sdpvar(2, 2, 'full');
    cp = P.coeffs(1);
    C = P + X;

    verifyCoeffExpr(testCase, C.coeffs(1), {cp{1} + X, cp{2} + X});
end

function testDpmatPromotion(testCase)
    % Coefficient-backed dpmat operands can enter affine dpvar expressions.
    P = dpvar(1, {[0 1]});
    A = dpmat({[0 1]}, {10, 20}, Degree=1);
    cp = P.coeffs(1);

    C = P + A;

    testCase.verifyEqual(C.Degree, 1);
    verifyCoeffExpr(testCase, C.coeffs(1), {cp{1} + 10, cp{2} + 20});
end

function testMixedScalarGridUsesCommonRefinement(testCase)
    % Same-bound mixed scalar grids should align on a common refinement.
    P = dpvar(1, {[0 1]});
    Q = dpvar(1, {[0 0.5 1]});
    cp = P.coeffs(1);
    cq1 = Q.coeffs(1);
    cq2 = Q.coeffs(2);

    S = P + Q;

    testCase.verifyEqual(S.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(S.Degree, 1);
    verifyCoeffExpr(testCase, S.coeffs(1), { ...
        cp{1} + cq1{1}, ...
        0.5 * cp{1} + 0.5 * cp{2} + cq1{2}});
    verifyCoeffExpr(testCase, S.coeffs(2), { ...
        0.5 * cp{1} + 0.5 * cp{2} + cq2{1}, ...
        cp{2} + cq2{2}});
end

function testRejectsUnsupportedOperands(testCase)
    % This slice rejects mixed bounds, bad sizes, function-only dpmat, and nonlinear sdpvar inputs.
    P = dpvar(1, {[0 1]});
    Q = dpvar(1, {[0 2]});
    R = dpvar(2, {[0 1]});
    F = dpmat({[0 1]}, @(rho) rho);
    x = sdpvar(1, 1);

    testCase.verifyError(@() P + Q, "dpvar:MixedGrid");
    testCase.verifyError(@() P + R, "dpvar:InvalidAddition");
    testCase.verifyError(@() P + F, "dpvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() P + x * x, "dpvar:InvalidAddition");
end

function testRateMetadataMustMatch(testCase)
    % Rate metadata is object state, so affine operands must agree.
    P = dpvar(1, {[0 1]}, RateBounds=[-1 1]);
    Q = dpvar(1, {[0 1]});

    testCase.verifyError(@() P + Q, "dpvar:InvalidAddition");
end

function verifyCoeffExpr(testCase, actual, expected)
    % Compare affine coefficient expressions by their normalized YALMIP bases.
    testCase.verifyEqual(numel(actual), numel(expected));
    for k = 1:numel(expected)
        diff = actual{k} - expected{k};
        testCase.verifyEqual(full(getbase(diff)), zeros(size(getbase(diff))), AbsTol=1e-10);
    end
end
