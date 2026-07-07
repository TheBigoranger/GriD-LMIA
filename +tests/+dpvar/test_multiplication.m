function tests = test_multiplication
    %TEST_MULTIPLICATION dpvar products with known data and affine guards.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
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

function verifyCoeffExpr(testCase, actual, expected)
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
