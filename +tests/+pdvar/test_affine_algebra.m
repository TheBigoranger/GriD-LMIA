function tests = test_affine_algebra
    %TEST_AFFINE_ALGEBRA Basic affine pdvar coefficient operations.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function testPlusMinusAndUnary(testCase)
    % Binary and unary operations should act coefficient-wise.
    P = pdvar(1, {[0 1]});
    Q = pdvar(1, {[0 1]});

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
    P = pdvar(2, {[0 1]}, "full");
    cp = P.coeffs(1);
    S = P + 5;
    D = eye(2) - P;

    verifyCoeffExpr(testCase, S.coeffs(1), {cp{1} + 5 * ones(2), cp{2} + 5 * ones(2)});
    verifyCoeffExpr(testCase, D.coeffs(1), {eye(2) - cp{1}, eye(2) - cp{2}});
end

function testAdditionZeroFastPathsRetainCompatibilityChecks(testCase)
    % Zero pdvar/pdmat/numeric operands preserve identity without skipping checks.
    P = pdvar(1, {[0 1]});
    Z = P - P;
    knownZero = pdmat({[0 1]}, {0}, Degree=0);

    testCase.verifyTrue(isequal(Z + P, P));
    testCase.verifyTrue(isequal(P + Z, P));
    testCase.verifyTrue(isequal(P + knownZero, P));
    testCase.verifyTrue(isequal(knownZero + P, P));
    testCase.verifyTrue(isequal(P + 0, P));
    testCase.verifyTrue(isequal(zeros(1) + P, P));

    matrixZero = pdmat({[0 1]}, {zeros(2)}, Degree=0);
    testCase.verifyError(@() P + matrixZero, "pdvar:InvalidAddition");

    otherGridZero = pdmat({[0 2]}, {0}, Degree=0);
    testCase.verifyError(@() P + otherGridZero, "pdvar:MixedGrid");
end

function testRateRowZeroAdditionRetainsRows(testCase)
    % A known zero rate table cannot take the metadata-free identity shortcut.
    rb = [-1 2];
    P = pdvar(1, [0 1]);
    cp = P.coeffs(1);
    Z = pdmat([0 1], {{0, 0; 0, 0}}, Degree=1, RateBounds=rb);

    S = P + Z;

    testCase.verifyTrue(S.HasRateDependence);
    testCase.verifyEqual(S.RateBounds, rb);
    verifyCoeffExpr(testCase, S.coeffs(1), {
        cp{1}, cp{2}
        cp{1}, cp{2}
        });
end

function testSdpvarPromotion(testCase)
    % Bare affine sdpvar matrices promote to constant coefficient data.
    P = pdvar(2, {[0 1]}, "full");
    X = sdpvar(2, 2, 'full');
    cp = P.coeffs(1);
    C = P + X;

    verifyCoeffExpr(testCase, C.coeffs(1), {cp{1} + X, cp{2} + X});
end

function testPdmatPromotion(testCase)
    % Coefficient-backed pdmat operands can enter affine pdvar expressions.
    P = pdvar(1, {[0 1]});
    A = pdmat({[0 1]}, {10, 20}, Degree=1);
    cp = P.coeffs(1);

    C = P + A;

    testCase.verifyEqual(C.Degree, 1);
    verifyCoeffExpr(testCase, C.coeffs(1), {cp{1} + 10, cp{2} + 20});
end

function testConstructorHighDegreeAlignment(testCase)
    % Arbitrary-degree constructor values participate in exact elevation.
    P = pdvar(1, {[0 1]}, Degree=2);
    Q = pdvar(1, {[0 1]}, Degree=3);
    cp = P.coeffs(1);
    cq = Q.coeffs(1);

    S = P + 5;
    D = P - Q;

    testCase.verifyEqual(S.Degree, 2);
    verifyCoeffExpr(testCase, S.coeffs(1), ...
        {cp{1} + 5, cp{2} + 5, cp{3} + 5});
    testCase.verifyEqual(D.Degree, 3);
    verifyCoeffExpr(testCase, D.coeffs(1), { ...
        cp{1} - cq{1}, ...
        (cp{1} + 2 * cp{2}) / 3 - cq{2}, ...
        (2 * cp{2} + cp{3}) / 3 - cq{3}, ...
        cp{3} - cq{4}});
end

function testDerivativeAffineOperandOrders(testCase)
    % Rate rows should work on either side of supported affine operands.
    P = pdvar(1, {[0 1]});
    Q = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);
    cq = Q.coeffs(1);
    X = sdpvar(1, 1);
    A = pdmat({[0 1]}, {10, 20}, Degree=1);

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
    P = pdvar(1, {[0 1]});
    Q = pdvar(1, {[0 0.5 1]});
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

function testAnisotropicPdvarAlignmentAndZeroAxisPromotion(testCase)
    % Affine sums align unequal degrees by componentwise maximum.
    grid = {[0 1], [10 20]};
    P = pdvar(1, grid, Degree=[1 3]);
    Q = pdvar(1, grid, Degree=[2 1]);
    pe = P.elevate([1 0]);
    qe = Q.elevate([0 2]);

    S = P + Q;
    R = P - Q;
    testCase.verifyEqual(S.Degree, [2 3]);
    testCase.verifyEqual(R.Degree, [2 3]);
    verifyCoeffExpr(testCase, S.coeffs([1 1]), ...
        cellfun(@plus, pe.coeffs([1 1]), qe.coeffs([1 1]), ...
        UniformOutput=false));
    verifyCoeffExpr(testCase, R.coeffs([1 1]), ...
        cellfun(@minus, pe.coeffs([1 1]), qe.coeffs([1 1]), ...
        UniformOutput=false));

    Z = pdvar(1, grid, Degree=[0 2]);
    plusRight = Z + 2;
    minusLeft = 2 - Z;
    testCase.verifyEqual(plusRight.Degree, [0 2]);
    testCase.verifyEqual(minusLeft.Degree, [0 2]);
    verifyCoeffExpr(testCase, plusRight.coeffs([1 1]), ...
        cellfun(@(x) x + 2, Z.coeffs([1 1]), UniformOutput=false));
    verifyCoeffExpr(testCase, minusLeft.coeffs([1 1]), ...
        cellfun(@(x) 2 - x, Z.coeffs([1 1]), UniformOutput=false));
end

function testExplicitPdmatRateRowsDispatchAndPreservation(testCase)
    % A known rate-row table should broadcast an ordinary decision on either side.
    rb = [-1 2];
    P = pdvar(1, [0 1], RateBounds=rb);
    cp = P.coeffs(1);
    R = pdmat([0 1], {{1, 3; 10, 14}}, ...
        Degree=1, RateBounds=rb);

    S = P + R;
    D = R - P;

    testCase.verifyClass(S, "pdvar");
    testCase.verifyClass(D, "pdvar");
    testCase.verifyTrue(S.HasRateDependence);
    testCase.verifyEqual(S.RateBounds, rb);
    testCase.verifyEqual(size(S.coeffs(1)), [2 2]);
    verifyCoeffExpr(testCase, S.coeffs(1), {
        cp{1} + 1, cp{2} + 3
        cp{1} + 10, cp{2} + 14
        });
    verifyCoeffExpr(testCase, D.coeffs(1), {
        1 - cp{1}, 3 - cp{2}
        10 - cp{1}, 14 - cp{2}
        });

    mismatch = pdmat([0 1], {{1, 2; 3, 4}}, ...
        Degree=1, RateBounds=[0 2]);
    testCase.verifyError(@() P + mismatch, "pdvar:InvalidAddition");
end

function testNonuniformQuadraticRefinementUsesForwardAlpha(testCase)
    % Restrict a coarse quadratic at alpha=5/12 onto two unequal cells.
    P = pdvar(1, {[-2 4]}, Degree=2);
    Q = pdvar(1, {[-2 0.5 4]}, Degree=2);
    cp = P.coeffs(1);
    cq1 = Q.coeffs(1);
    cq2 = Q.coeffs(2);

    S = P + Q;

    shared = (49 * cp{1} + 70 * cp{2} + 25 * cp{3}) / 144;
    testCase.verifyEqual(S.GridInfo.Vectors{1}, [-2 0.5 4]);
    testCase.verifyEqual(S.Degree, 2);
    verifyCoeffExpr(testCase, S.coeffs(1), { ...
        cp{1} + cq1{1}, ...
        (7 * cp{1} + 5 * cp{2}) / 12 + cq1{2}, ...
        shared + cq1{3}});
    verifyCoeffExpr(testCase, S.coeffs(2), { ...
        shared + cq2{1}, ...
        (7 * cp{2} + 5 * cp{3}) / 12 + cq2{2}, ...
        cp{3} + cq2{3}});
end

function testRejectsUnsupportedOperands(testCase)
    % This slice rejects mixed bounds, bad sizes, function-only pdmat, and nonlinear sdpvar inputs.
    P = pdvar(1, {[0 1]});
    Q = pdvar(1, {[0 2]});
    R = pdvar(2, {[0 1]});
    F = pdmat({[0 1]}, @(rho) rho);
    x = sdpvar(1, 1);

    testCase.verifyError(@() P + Q, "pdvar:MixedGrid");
    testCase.verifyError(@() P + R, "pdvar:InvalidAddition");
    testCase.verifyError(@() P + F, "pdvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() P + x * x, "pdvar:InvalidAddition");
end

function testRejectsUnsupportedDerivativeAffineOperands(testCase)
    % Rate-row expressions cannot be resampled or mixed with bad operands.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    D = rhodiff(P);
    Q = pdvar(2, {[0 1]}, RateBounds=[-1 1]);
    R = pdvar(1, {[0 1]}, RateBounds=[0 1]);
    A = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho);
    x = sdpvar(1, 1);

    testCase.verifyError(@() D + Q, "pdvar:InvalidAddition");
    testCase.verifyError(@() D + R, "pdvar:InvalidAddition");
    testCase.verifyError(@() D + A, "pdvar:InvalidAddition");
    testCase.verifyError(@() D + F, "pdvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() D + x * x, "pdvar:InvalidAddition");
end

function testRateMetadataPropagatesAndChecksMismatch(testCase)
    % Missing RateBounds should inherit the operation-level metadata.
    rb = [-1 1];
    P = pdvar(1, {[0 1]}, RateBounds=rb);
    Q = pdvar(1, {[0 1]});
    R = pdvar(1, {[0 1]}, RateBounds=[0 1]);
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
    testCase.verifyError(@() P + R, "pdvar:InvalidAddition");
end

function testZeroAffineCancellationsClearMetadata(testCase)
    % Cancelled affine expressions should become compact nondecision zeros.
    P = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 1]);

    Z1 = P - P;
    Z2 = P + (-P);
    Z3 = D - D;

    verifyZeroPdvar(testCase, Z1, [1 1]);
    verifyZeroPdvar(testCase, Z2, [1 1]);
    verifyZeroPdvar(testCase, Z3, [1 1]);
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

function verifyZeroPdvar(testCase, obj, sz)
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
