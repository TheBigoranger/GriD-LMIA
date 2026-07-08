function tests = test_construction
    %TEST_CONSTRUCTION dpmat constructor source modes and inherited state.
    tests = functiontests(localfunctions);
end

function testFunctionDefaultDegree(testCase)
    % Function-backed construction should keep the exact handle and placeholders.
    A = dpmat({[0 1 2]}, @(rho) [rho, rho + 1]);

    testCase.verifyClass(A, "dpmat");
    testCase.verifyTrue(isa(A, "dpbase"));
    testCase.verifyEqual(A.Degree, 1);
    testCase.verifyEqual(size(A), [1 2]);
    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyFalse(A.ContainsDecision);
    testCase.verifyFalse(A.HasRateDependence);
    testCase.verifyEmpty(A.RateBounds);
    testCase.verifyEqual(A.SourceSummary, "function");
    testCase.verifyEqual(A.FunctionHandle(2), [2 3]);

    testCase.verifyEqual(A.coeffs(1), {zeros(1, 2), zeros(1, 2)});
    testCase.verifyEqual(A.coeffs(2), {zeros(1, 2), zeros(1, 2)});
end

function testFunctionCustomDegreeTensor(testCase)
    % Explicit-degree tensor functions should populate Bernstein coefficients.
    A = dpmat({[0 2], [10 14]}, @(rho, eta) [rho + eta; rho - eta], Degree=2);

    testCase.verifyEqual(A.Degree, 2);
    testCase.verifyEqual(A.npar(), 2);
    testCase.verifyEqual(A.ncoeff(), 9);
    testCase.verifyEqual(size(A), [2 1]);
    testCase.verifyEqual(A.SourceSummary, "function-bernstein");
    testCase.verifyEqual(A.FunctionHandle(2, 14), [16; -12]);

    coeffs = A.coeffs([1 1]);
    testCase.verifyEqual(coeffs{1}, [10; -10], AbsTol=1e-10);
    testCase.verifyEqual(coeffs{5}, [13; -11], AbsTol=1e-10);
    testCase.verifyEqual(coeffs{9}, [16; -12], AbsTol=1e-10);
end

function testFunctionDegreePopulatesPolynomialCoefficients(testCase)
    % Polynomial handles should become coefficient-backed when Degree is explicit.
    A = dpmat({[0 2]}, @(rho) rho.^2, Degree=2);

    testCase.verifyEqual(A.SourceSummary, "function-bernstein");
    testCase.verifyEqual(A.FunctionHandle(3), 9);
    coeffs = A.coeffs(1);
    testCase.verifyEqual(coeffs{1}, 0, AbsTol=1e-10);
    testCase.verifyEqual(coeffs{2}, 0, AbsTol=1e-10);
    testCase.verifyEqual(coeffs{3}, 4, AbsTol=1e-10);
end

function testFunctionDoesNotSampleWholeGrid(testCase)
    % Function-only construction should probe size without sampling every node.
    A = dpmat({[0 1 2]}, @lowerOnly);

    testCase.verifyEqual(A.Degree, 1);
    testCase.verifyEqual(A.MatrixSize, [1 2]);
    testCase.verifyEqual(A.SourceSummary, "function");
    testCase.verifyEqual(A.coeffs(2), {zeros(1, 2), zeros(1, 2)});
end

function testGlobalDegreeTwoScalar(testCase)
    % Scalar global Bernstein data should form overlapping local cells.
    data = {10, 11, 12, 13, 14};
    A = dpmat({[0 1 2]}, data, Degree=2);

    testCase.verifyEqual(A.Degree, 2);
    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyEqual(A.SourceSummary, "coefficient-backed");
    testCase.verifyEmpty(A.FunctionHandle);
    testCase.verifyEqual(A.coeffs(1), {10, 11, 12});
    testCase.verifyEqual(A.coeffs(2), {12, 13, 14});
end

function testTensorGlobalCellGrid(testCase)
    % Tensor global cell data should preserve grid metadata and local order.
    data = cell(3, 2);
    for i = 1:3
        for j = 1:2
            data{i, j} = [i, j];
        end
    end

    A = dpmat({[0 1 2], [10 20]}, data, Degree=1);

    coeffs = A.coeffs([2 1]);
    testCase.verifyEqual(A.GridInfo.NumNodes, [3 2]);
    testCase.verifyEqual(A.GridInfo.Bounds, [0 2; 10 20]);
    testCase.verifyEqual(A.GridInfo.Points, [
        0 10
        0 20
        1 10
        1 20
        2 10
        2 20
        ]);
    testCase.verifyEqual(A.MatrixSize, [1 2]);
    testCase.verifyEqual(coeffs, {[2 1], [2 2], [3 1], [3 2]});
end

function testExplicitNestedLocalValues(testCase)
    % Explicit nested LocalValues should pass through as local coefficients.
    localValues = {
        {mkCoeff(100)}, ...
        {mkCoeff(200)}
        };

    A = dpmat({[0 1 2], [10 20]}, localValues);

    testCase.verifyEqual(A.Degree, 1);
    testCase.verifyEqual(A.MatrixSize, [1 2]);
    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyEqual(A.LocalValues{2}{1}, mkCoeff(200));
    testCase.verifyEqual(A.coeffs([1 1]), mkCoeff(100));
end

function c = mkCoeff(offset)
    % Keep matrix payloads distinct while preserving flat coefficient order.
    c = {
        [offset + 1, offset + 2], ...
        [offset + 3, offset + 4], ...
        [offset + 5, offset + 6], ...
        [offset + 7, offset + 8]
        };
end

function out = lowerOnly(rho)
    % Guard that function-backed construction probes only the lower grid point.
    if rho ~= 0
        error("test:UnexpectedSample", "Constructor should only probe the lower point.");
    end
    out = [1 2];
end
