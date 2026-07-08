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

function testDerivativeAffineOperandOrders(testCase)
    % Rate rows should work on either side of supported affine operands.
    P = dpvar(1, {[0 1]});
    Q = dpvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);
    cq = Q.coeffs(1);
    X = sdpvar(1, 1);
    A = dpmat({[0 1]}, {10, 20}, Degree=1);

    L = D + Q;
    R = Q + D;
    N = 5 - D;
    S = D + 5;
    Y = X - D;
    K = A - D;

    testCase.verifyEqual(L.Degree, 1);
    testCase.verifyTrue(L.HasRateDependence);
    testCase.verifyEqual(L.RateBounds, [-1 2]);
    verifyCoeffExpr(testCase, L.coeffs(1), {
        cd{1, 1} + cq{1}, cd{1, 1} + cq{2}
        cd{2, 1} + cq{1}, cd{2, 1} + cq{2}
    });
    verifyCoeffExpr(testCase, R.coeffs(1), {
        cq{1} + cd{1, 1}, cq{2} + cd{1, 1}
        cq{1} + cd{2, 1}, cq{2} + cd{2, 1}
    });
    verifyCoeffExpr(testCase, N.coeffs(1), {5 - cd{1, 1}; 5 - cd{2, 1}});
    verifyCoeffExpr(testCase, S.coeffs(1), {cd{1, 1} + 5; cd{2, 1} + 5});
    verifyCoeffExpr(testCase, Y.coeffs(1), {X - cd{1, 1}; X - cd{2, 1}});
    verifyCoeffExpr(testCase, K.coeffs(1), {
        10 - cd{1, 1}, 20 - cd{1, 1}
        10 - cd{2, 1}, 20 - cd{2, 1}
    });
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

function testRejectsUnsupportedDerivativeAffineOperands(testCase)
    % Rate-row expressions cannot be resampled or mixed with bad operands.
    P = dpvar(1, {[0 1]}, RateBounds=[-1 1]);
    D = rhodiff(P);
    Q = dpvar(2, {[0 1]}, RateBounds=[-1 1]);
    R = dpvar(1, {[0 1]}, RateBounds=[0 1]);
    A = dpmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    F = dpmat({[0 1]}, @(rho) rho);
    x = sdpvar(1, 1);

    testCase.verifyError(@() D + Q, "dpvar:InvalidAddition");
    testCase.verifyError(@() D + R, "dpvar:InvalidAddition");
    testCase.verifyError(@() D + A, "dpvar:InvalidAddition");
    testCase.verifyError(@() D + F, "dpvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() D + x * x, "dpvar:InvalidAddition");
end

function testRateMetadataPropagatesAndChecksMismatch(testCase)
    % Missing RateBounds should inherit the operation-level metadata.
    rb = [-1 1];
    P = dpvar(1, {[0 1]}, RateBounds=rb);
    Q = dpvar(1, {[0 1]});
    R = dpvar(1, {[0 1]}, RateBounds=[0 1]);
    cp = P.coeffs(1);
    cq = Q.coeffs(1);

    S = P + Q;
    D = Q - P;

    testCase.verifyTrue(S.HasRateDependence);
    testCase.verifyTrue(D.HasRateDependence);
    testCase.verifyEqual(S.RateBounds, rb);
    testCase.verifyEqual(D.RateBounds, rb);
    verifyCoeffExpr(testCase, S.coeffs(1), {cp{1} + cq{1}, cp{2} + cq{2}});
    verifyCoeffExpr(testCase, D.coeffs(1), {cq{1} - cp{1}, cq{2} - cp{2}});
    testCase.verifyError(@() P + R, "dpvar:InvalidAddition");
end

function testZeroAffineCancellationsClearMetadata(testCase)
    % Cancelled affine expressions should become compact nondecision zeros.
    P = dpvar(1, {[0 1]});
    D = rhodiff(P, [-1 1]);

    Z1 = P - P;
    Z2 = P + (-P);
    Z3 = D - D;

    verifyZeroDpvar(testCase, Z1, [1 1]);
    verifyZeroDpvar(testCase, Z2, [1 1]);
    verifyZeroDpvar(testCase, Z3, [1 1]);
    testCase.verifyTrue(isequal(Z1 + P, P));
    testCase.verifyTrue(isequal(P - Z1, P));
end

function verifyCoeffExpr(testCase, actual, expected)
    % Compare affine coefficient expressions by their normalized YALMIP bases.
    testCase.verifyEqual(numel(actual), numel(expected));
    for k = 1:numel(expected)
        diff = actual{k} - expected{k};
        testCase.verifyEqual(full(getbase(diff)), zeros(size(getbase(diff))), AbsTol=1e-10);
    end
end

function verifyZeroDpvar(testCase, obj, sz)
    % Arithmetic fast paths should remove stale YALMIP/rate metadata.
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.Degree, 0);
    testCase.verifyFalse(obj.ContainsDecision);
    testCase.verifyFalse(obj.HasRateDependence);
    testCase.verifyEmpty(obj.RateBounds);
    coeffs = obj.coeffs(ones(1, obj.npar()));
    testCase.verifyEqual(numel(coeffs), 1);
    testCase.verifyEqual(coeffs{1}, zeros(sz));
end
