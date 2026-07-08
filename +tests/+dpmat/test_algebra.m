function tests = test_algebra
    %TEST_ALGEBRA Coefficient-backed dpmat arithmetic.
    tests = functiontests(localfunctions);
end

function testAdditionElevatesDegree(testCase)
    % Addition should elevate lower-degree operands before summing coefficients.
    A = dpmat({[0 1]}, {1, 2}, Degree=1);
    B = dpmat({[0 1]}, {10, 20, 30}, Degree=2);

    C = A + B;

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyTrue(C.IsContinuous);
    testCase.verifyEqual(C.SourceSummary, "coefficient-backed");
    testCase.verifyEmpty(C.FunctionHandle);
    verifyCoeff(testCase, C, 1, {11, 21.5, 32});
end

function testSubtractionAndUnaryMinus(testCase)
    % Subtraction and unary minus should operate coefficient-wise.
    A = dpmat({[0 1]}, {1, 3}, Degree=1);
    B = dpmat({[0 1]}, {4, 8}, Degree=1);

    verifyCoeff(testCase, B - A, 1, {3, 5});
    verifyCoeff(testCase, -A, 1, {-1, -3});
end

function testMatrixMultiplicationDegreeGrowth(testCase)
    % Matrix multiplication should convolve Bernstein coefficients and grow degree.
    A = dpmat({[0 1]}, {[1 2], [3 4]}, Degree=1);
    B = dpmat({[0 1]}, {[5; 6], [7; 8]}, Degree=1);

    C = A * B;

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyEqual(size(C), [1 1]);
    verifyCoeff(testCase, C, 1, {17, 31, 53});
end

function testChainedScalarMultiplicationCubicCoefficients(testCase)
    % Chained scalar products should retain cubic Bernstein coefficients.
    A = dpmat({[0 1]}, {2, 5}, Degree=1);
    B = dpmat({[0 1]}, {7, 11}, Degree=1);
    C = dpmat({[0 1]}, {3, 4}, Degree=1);

    L = A * B * C;

    testCase.verifyEqual(L.Degree, 3);
    verifyCoeff(testCase, L, 1, {42, 227 / 3, 131, 220});
end

function testTensorGridCoefficientProduct(testCase)
    % Tensor-grid products should preserve tensor coefficient ordering.
    grid = {[0 1], [10 20]};
    A = dpmat(grid, {1 2; 3 4}, Degree=1);
    B = dpmat(grid, {5 6; 7 8}, Degree=1);

    K = A * B;
    coeffs = K.coeffs([1 1]);

    testCase.verifyEqual(K.Degree, 2);
    testCase.verifyEqual(size(K), [1 1]);
    testCase.verifyEqual(numel(coeffs), 9);
    testCase.verifyEqual(coeffs{1}, 5);
    testCase.verifyEqual(coeffs{5}, 15);
    testCase.verifyEqual(coeffs{9}, 32);
end

function testMixedScalarGridUsesCommonRefinement(testCase)
    % Same-bound mixed scalar grids should align on a common refinement.
    A = dpmat({[0 1]}, {1, 2}, Degree=1);
    B = dpmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);

    S = A + B;
    P = A * B;

    testCase.verifyEqual(S.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(P.GridInfo.Vectors{1}, [0 0.5 1]);
    verifyCoeff(testCase, S, 1, {11, 21.5});
    verifyCoeff(testCase, S, 2, {21.5, 32});
    verifyCoeff(testCase, P, 1, {10, 17.5, 30});
    verifyCoeff(testCase, P, 2, {30, 42.5, 60});
end

function testNumericPromotion(testCase)
    % Numeric scalars should promote to compatible constant dpmat operands.
    A = dpmat({[0 1]}, {1, 2}, Degree=1);

    verifyCoeff(testCase, A + 5, 1, {6, 7});
    verifyCoeff(testCase, 5 - A, 1, {4, 3});
    verifyCoeff(testCase, 2 * A, 1, {2, 4});
    verifyCoeff(testCase, A * 3, 1, {3, 6});
end

function testNumericMatrixMultiplication(testCase)
    % Numeric matrices should multiply dpmat operands on either side.
    A = dpmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);

    L = [1 0] * A;
    R = A * [1; 2];

    testCase.verifyEqual(size(L), [1 2]);
    testCase.verifyEqual(size(R), [2 1]);
    verifyCoeff(testCase, L, 1, {[1 2], [5 6]});
    verifyCoeff(testCase, R, 1, {[5; 11], [17; 23]});
end

function testAlgebraRejectsIncompatibleInputs(testCase)
    % Algebra should reject size, grid-bound, and function-only incompatibilities.
    A = dpmat({[0 1]}, {ones(1, 2), 2 * ones(1, 2)}, Degree=1);
    B = dpmat({[0 1]}, {1, 2}, Degree=1);
    C = dpmat({[0 2]}, {1, 2}, Degree=1);
    F = dpmat({[0 1]}, @(rho) rho);

    testCase.verifyError(@() A + B, "dpmat:InvalidAddition");
    testCase.verifyError(@() A * A, "dpmat:InvalidMultiplication");
    testCase.verifyError(@() B + C, "dpmat:MixedGrid");
    testCase.verifyError(@() F + 1, "dpmat:FunctionOnlyAlgebra");
end

function testFunctionBernsteinCanEnterAlgebra(testCase)
    % Function handles with Bernstein evidence should enter coefficient algebra.
    A = dpmat({[0 1]}, @(rho) rho, Degree=1);

    C = A + 1;

    testCase.verifyEqual(C.SourceSummary, "coefficient-backed");
    verifyCoeff(testCase, C, 1, {1, 2});
end

function verifyCoeff(testCase, obj, cellSubs, expected)
    % Compare one physical cell's coefficients against numeric expectations.
    coeffs = obj.coeffs(cellSubs);
    testCase.verifyEqual(numel(coeffs), numel(expected));
    for k = 1:numel(expected)
        testCase.verifyEqual(coeffs{k}, expected{k}, AbsTol=1e-10);
    end
end
