function tests = test_multiplication
    %TEST_MULTIPLICATION dpvar products with known data and affine guards.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function testDpmatDpvarProducts(testCase)
    % Known coefficient data may multiply a dpvar on either side.
    P = dpvar(1, {[0 1]});
    A = dpmat({[0 1]}, {10, 20}, Degree=1);
    cp = P.coeffs(1);

    L = A * P;
    R = P * A;

    testCase.verifyEqual(L.Degree, 2);
    testCase.verifyEqual(R.Degree, 2);
    exp = {10 * cp{1}, (10 * cp{2} + 20 * cp{1}) / 2, 20 * cp{2}};
    verifyCoeffExpr(testCase, L.coeffs(1), exp);
    verifyCoeffExpr(testCase, R.coeffs(1), exp);
end

function testNumericScalarAndMatrixProducts(testCase)
    % Numeric products should preserve affine YALMIP structure.
    P = dpvar(2, 1, {[0 1]}, "full");
    cp = P.coeffs(1);

    S = 3 * P;
    L = [1 2] * P;
    R = P * [4 5];

    testCase.verifyEqual(size(S), [2 1]);
    testCase.verifyEqual(size(L), [1 1]);
    testCase.verifyEqual(size(R), [2 2]);
    verifyCoeffExpr(testCase, S.coeffs(1), {3 * cp{1}, 3 * cp{2}});
    verifyCoeffExpr(testCase, L.coeffs(1), {[1 2] * cp{1}, [1 2] * cp{2}});
    verifyCoeffExpr(testCase, R.coeffs(1), {cp{1} * [4 5], cp{2} * [4 5]});
end

function testScalarDpvarScalesKnownMatrices(testCase)
    % A scalar dpvar expression should scale known matrices like an sdpvar.
    G = dpvar(1, [0 1], Degree=0);
    cg = G.coeffs(1);

    R = G * eye(2);
    L = eye(2) * G;

    testCase.verifyEqual(size(R), [2 2]);
    testCase.verifyEqual(size(L), [2 2]);
    testCase.verifyEqual(R.Degree, 0);
    testCase.verifyEqual(L.Degree, 0);
    verifyCoeffExpr(testCase, R.coeffs(1), {cg{1} * eye(2)});
    verifyCoeffExpr(testCase, L.coeffs(1), {eye(2) * cg{1}});
end

function testDerivativeProductsPreserveRateRows(testCase)
    % Known-data products should preserve one output row per rate vertex.
    P = dpvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);
    A = dpmat({[0 1]}, {10, 20}, Degree=1);

    L = A * D;
    R = D * A;
    S = 3 * D;
    T = D * 4;

    testCase.verifyEqual(L.Degree, 1);
    testCase.verifyTrue(L.HasRateDependence);
    testCase.verifyEqual(L.RateBounds, [-1 2]);
    verifyCoeffExpr(testCase, L.coeffs(1), {
        10 * cd{1, 1}, 20 * cd{1, 1}
        10 * cd{2, 1}, 20 * cd{2, 1}
    });
    verifyCoeffExpr(testCase, R.coeffs(1), {
        cd{1, 1} * 10, cd{1, 1} * 20
        cd{2, 1} * 10, cd{2, 1} * 20
    });
    verifyCoeffExpr(testCase, S.coeffs(1), {3 * cd{1, 1}; 3 * cd{2, 1}});
    verifyCoeffExpr(testCase, T.coeffs(1), {cd{1, 1} * 4; cd{2, 1} * 4});
end

function testDerivativeNumericMatrixProducts(testCase)
    % Numeric matrices may multiply a rate-row vector on either side.
    V = dpvar(2, 1, {[0 1]}, "full");
    D = rhodiff(V, [-1 1]);
    cd = D.coeffs(1);

    L = [1 2] * D;
    R = D * [4 5];

    testCase.verifyEqual(size(L), [1 1]);
    testCase.verifyEqual(size(R), [2 2]);
    verifyCoeffExpr(testCase, L.coeffs(1), {[1 2] * cd{1, 1}; [1 2] * cd{2, 1}});
    verifyCoeffExpr(testCase, R.coeffs(1), {cd{1, 1} * [4 5]; cd{2, 1} * [4 5]});
end

function testMixedScalarGridUsesCommonRefinement(testCase)
    % Products on same-bound mixed grids are recomputed cell-locally.
    P = dpvar(1, {[0 1]});
    A = dpmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    cp = P.coeffs(1);

    C = P * A;

    testCase.verifyEqual(C.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(C.Degree, 2);
    pMid = 0.5 * cp{1} + 0.5 * cp{2};
    verifyCoeffExpr(testCase, C.coeffs(1), { ...
        cp{1} * 10, ...
        (cp{1} * 20 + pMid * 10) / 2, ...
        pMid * 20});
    verifyCoeffExpr(testCase, C.coeffs(2), { ...
        pMid * 20, ...
        (pMid * 30 + cp{2} * 20) / 2, ...
        cp{2} * 30});
end

function testComposedKnownDecisionExpression(testCase)
    % Chained affine products should preserve degree growth and coefficients.
    P = dpvar(1, {[0 1]});
    A = dpmat({[0 1]}, {10, 20}, Degree=1);
    B = dpmat({[0 1]}, {1, 2, 3}, Degree=2);
    C = dpmat({[0 1]}, {4, 5}, Degree=1);
    D = dpmat({[0 1]}, {7, 8, 9, 10}, Degree=3);
    cp = P.coeffs(1);

    E = (P * A + B) * C - D;

    s0 = 10 * cp{1} + 1;
    s1 = (20 * cp{1} + 10 * cp{2}) / 2 + 2;
    s2 = 20 * cp{2} + 3;
    testCase.verifyEqual(E.Degree, 3);
    verifyCoeffExpr(testCase, E.coeffs(1), { ...
        s0 * 4 - 7, ...
        s0 * 5 / 3 + s1 * 8 / 3 - 8, ...
        s1 * 10 / 3 + s2 * 4 / 3 - 9, ...
        s2 * 5 - 10});
end

function testRejectsUnsupportedProducts(testCase)
    % Products that leave the affine SDP layer should fail clearly.
    P = dpvar(1, {[0 1]});
    Q = dpvar(1, {[0 1]});
    R = dpvar(1, {[0 1]}, RateBounds=[-1 1]);
    V = dpvar(2, 1, {[0 1]}, "full");
    A = dpmat({[0 2]}, {1, 2}, Degree=1);
    B = dpmat({[0 1]}, {ones(2), 2 * ones(2)}, Degree=1);
    F = dpmat({[0 1]}, @(rho) rho);
    x = sdpvar(1, 1);

    testCase.verifyError(@() P * Q, "dpvar:InvalidMultiplication");
    testCase.verifyError(@() P * x, "dpvar:InvalidMultiplication");
    testCase.verifyError(@() P * F, "dpvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() P * A, "dpvar:MixedGrid");
    testCase.verifyError(@() V * B, "dpvar:InvalidMultiplication");
    testCase.verifyError(@() R * 2, "dpvar:InvalidMultiplication");
end

function testRejectsUnsupportedDerivativeProducts(testCase)
    % Rate-row products require a matching-grid known-data partner.
    P = dpvar(1, {[0 1]});
    D = rhodiff(P, [-1 1]);
    Q = dpvar(1, {[0 1]});
    R = dpvar(1, {[0 1]}, RateBounds=[-1 1]);
    A = dpmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    B = dpmat({[0 2]}, {10, 20}, Degree=1);

    testCase.verifyError(@() D * D, "dpvar:InvalidMultiplication");
    testCase.verifyError(@() D * Q, "dpvar:InvalidMultiplication");
    testCase.verifyError(@() Q * D, "dpvar:InvalidMultiplication");
    testCase.verifyError(@() D * A, "dpvar:InvalidMultiplication");
    testCase.verifyError(@() A * D, "dpvar:InvalidMultiplication");
    testCase.verifyError(@() D * B, "dpvar:MixedGrid");
    testCase.verifyError(@() R * 2, "dpvar:InvalidMultiplication");
end

function verifyCoeffExpr(testCase, actual, expected)
    % Compare numeric or affine coefficient expressions without solving them.
    testCase.verifyEqual(numel(actual), numel(expected));
    for k = 1:numel(expected)
        diff = actual{k} - expected{k};
        if isa(diff, "sdpvar")
            base = full(getbase(diff));
            testCase.verifyEqual(base, zeros(size(base)), AbsTol=1e-10);
        else
            testCase.verifyEqual(diff, zeros(size(diff)), AbsTol=1e-10);
        end
    end
end
