function tests = test_construction
    %TEST_CONSTRUCTION pdmat constructor source modes and inherited state.
    tests = functiontests(localfunctions);
end

function testFunctionDefaultDegree(testCase)
    % Function-backed construction should keep the exact handle and placeholders.
    A = pdmat({[0 1 2]}, @(rho) [rho, rho + 1]);

    testCase.verifyClass(A, "pdmat");
    testCase.verifyTrue(isa(A, "pdbase"));
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
    A = pdmat({[0 2], [10 14]}, @(rho, eta) [rho + eta; rho - eta], Degree=2);

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
    A = pdmat({[0 2]}, @(rho) rho.^2, Degree=2);

    testCase.verifyEqual(A.SourceSummary, "function-bernstein");
    testCase.verifyEqual(A.FunctionHandle(3), 9);
    coeffs = A.coeffs(1);
    testCase.verifyEqual(coeffs{1}, 0, AbsTol=1e-10);
    testCase.verifyEqual(coeffs{2}, 0, AbsTol=1e-10);
    testCase.verifyEqual(coeffs{3}, 4, AbsTol=1e-10);
end

function testFunctionDegreeUsesForwardAlphaOnNonuniformCells(testCase)
    % Each cell should order fitted controls from its physical lower to upper face.
    A = pdmat({[-2 0.5 4]}, @(rho) rho.^2, Degree=2);
    first = A.coeffs(1);
    second = A.coeffs(2);

    testCase.verifyEqual(A.Degree, 2);
    testCase.verifyEqual([first{:}], [4, -1, 0.25], AbsTol=1e-10);
    testCase.verifyEqual([second{:}], [0.25, 2, 16], AbsTol=1e-10);
end

function testScalarGridVectorShorthand(testCase)
    % A plain numeric vector is accepted as the one-parameter grid.
    A = pdmat([0 1 2], {10, 20, 30}, Degree=1);

    testCase.verifyEqual(A.Degree, 1);
    testCase.verifyEqual(A.GridInfo.Vectors, {[0 1 2]});
    testCase.verifyEqual(A.coeffs(2), {20, 30});
end

function testFunctionDoesNotSampleWholeGrid(testCase)
    % Function-only construction should probe size without sampling every node.
    A = pdmat({[0 1 2]}, @lowerOnly);

    testCase.verifyEqual(A.Degree, 1);
    testCase.verifyEqual(A.MatrixSize, [1 2]);
    testCase.verifyEqual(A.SourceSummary, "function");
    testCase.verifyEqual(A.coeffs(2), {zeros(1, 2), zeros(1, 2)});
end

function testGlobalDegreeTwoScalar(testCase)
    % Scalar global Bernstein data should form overlapping local cells.
    data = {10, 11, 12, 13, 14};
    A = pdmat({[0 1 2]}, data, Degree=2);

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

    A = pdmat({[0 1 2], [10 20]}, data, Degree=1);

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
    % Misaligned nested LocalValues should warn without changing their data.
    localValues = {
        {mkCoeff(100)}, ...
        {mkCoeff(200)}
        };

    A = constructWithWarning(testCase, ...
        @() pdmat({[0 1 2], [10 20]}, localValues), ...
        "pdmat:DiscontinuousLocalValues");

    testCase.verifyEqual(A.Degree, 1);
    testCase.verifyEqual(A.MatrixSize, [1 2]);
    testCase.verifyFalse(A.IsContinuous);
    testCase.verifyEqual(A.LocalValues{1}{1}, mkCoeff(100));
    testCase.verifyEqual(A.LocalValues{2}{1}, mkCoeff(200));
    testCase.verifyEqual(A.coeffs([1 1]), mkCoeff(100));
end

function testTwoDimensionalGlobalBernsteinData(testCase)
    % A 3-by-3 global degree-one grid should share faces in both directions.
    grid = {[0 1 2], [10 20 30]};
    data = cell(3, 3);
    for i = 1:3
        for j = 1:3
            data{i, j} = 10 * i + j;
        end
    end

    A = constructWarningFree(testCase, @() pdmat(grid, data, Degree=1));
    c11 = A.coeffs([1 1]);
    c21 = A.coeffs([2 1]);
    c12 = A.coeffs([1 2]);

    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyEqual(c11, {11, 12, 21, 22});
    testCase.verifyEqual(A.coeffs([2 2]), {22, 23, 32, 33});
    testCase.verifyEqual(c11([3 4]), c21([1 2]));
    testCase.verifyEqual(c11([2 4]), c12([1 3]));
end

function testTwoDimensionalAlignedNestedLocalValues(testCase)
    % Explicit tensor local values remain continuous when every face agrees.
    grid = {[0 1 2], [10 20 30]};
    localValues = mkAligned2DLocalValues();

    A = constructWarningFree(testCase, @() pdmat(grid, localValues, Degree=1));

    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyEqual(A.LocalValues{2}{1}, {21, 22, 31, 32});
    testCase.verifyEqual(A.LocalValues{1}{2}, {12, 13, 22, 23});
    testCase.verifyEqual(A.coeffs([1 1]), {11, 12, 21, 22});
end

function testNestedLocalValuesContinuityTolerance(testCase)
    % Shared faces use the package's scale-aware numerical tolerance.
    grid = {[0 1 2]};
    withinTol = {{1, 2}, {2 + 1e-10, 3}};
    beyondTol = {{1, 2}, {2 + 1e-6, 3}};

    A = constructWarningFree(testCase, @() pdmat(grid, withinTol, Degree=1));
    B = constructWithWarning(testCase, @() pdmat(grid, beyondTol, Degree=1), ...
        "pdmat:DiscontinuousLocalValues");

    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyFalse(B.IsContinuous);
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

function vals = mkAligned2DLocalValues()
    % Keep tensor labels ordered as [0 0], [0 1], [1 0], [1 1].
    vals = {
        {{11, 12, 21, 22}, {12, 13, 22, 23}}, ...
        {{21, 22, 31, 32}, {22, 23, 32, 33}}
        };
end

function obj = constructWithWarning(testCase, fcn, warningId)
    % Capture one direct-construction warning while retaining its result.
    obj = [];
    testCase.verifyWarning(@construct, warningId);

    function construct
        obj = fcn();
    end
end

function obj = constructWarningFree(testCase, fcn)
    % Capture a construction result while asserting no warning escapes.
    obj = [];
    testCase.verifyWarningFree(@construct);

    function construct
        obj = fcn();
    end
end

function out = lowerOnly(rho)
    % Guard that function-backed construction probes only the lower grid point.
    if rho ~= 0
        error("test:UnexpectedSample", "Constructor should only probe the lower point.");
    end
    out = [1 2];
end
