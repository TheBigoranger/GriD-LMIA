function tests = test_construction
    %TEST_CONSTRUCTION pdmat constructor source modes and inherited state.
    tests = functiontests(localfunctions);
end

function testFunDefDeg(testCase)
    % Function-backed construction should keep the exact handle and
    % placeholders.
    A = pdmat({[0 1 2]}, @(rho) [rho, rho + 1]);

    testCase.verifyClass(A, "pdmat");
    testCase.verifyTrue(isa(A, "pdbase"));
    testCase.verifyEqual(A.Degree, 1);
    testCase.verifyEqual(size(A), [1 2]);
    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyFalse(A.ContainsDecision);
    testCase.verifyEmpty(A.RateBounds);
    testCase.verifyEqual(A.SourceSummary, "function");
    testCase.verifyEqual(A.FunctionHandle(2), [2 3]);

    testCase.verifyEqual(A.coeffs(1), {zeros(1, 2), zeros(1, 2)});
    testCase.verifyEqual(A.coeffs(2), {zeros(1, 2), zeros(1, 2)});
end

function testFunNonDegTen(testCase)
    % Explicit-degree tensor functions should populate Bernstein
    % coefficients.
    A = pdmat({[0 2], [10 14]}, ...
        @(rho, eta) [rho + eta.^2; rho - eta.^2], Degree=[1 2]);

    testCase.verifyEqual(A.Degree, [1 2]);
    testCase.verifyEqual(A.npar(), 2);
    testCase.verifyEqual(A.ncoeff(), 6);
    testCase.verifyEqual(size(A), [2 1]);
    testCase.verifyEqual(A.SourceSummary, "function-bernstein");
    testCase.verifyEqual(A.FunctionHandle(2, 14), [198; -194]);

    coeffs = A.coeffs([1 1]);
    testCase.verifyEqual(coeffs{1}, [100; -100], AbsTol=1e-10);
    testCase.verifyEqual(coeffs{5}, [142; -138], AbsTol=1e-10);
    testCase.verifyEqual(coeffs{6}, [198; -194], AbsTol=1e-10);
    testCase.verifyEqual(A.evaluate([0.5 11]), [121.5; -120.5], AbsTol=1e-10);
end

function testFunDegPopPolCoe(testCase)
    % Polynomial handles should become coefficient-backed when Degree is
    % explicit.
    A = pdmat({[0 2]}, @(rho) rho.^2, Degree=2);

    testCase.verifyEqual(A.SourceSummary, "function-bernstein");
    testCase.verifyEqual(A.FunctionHandle(3), 9);
    coeffs = A.coeffs(1);
    testCase.verifyEqual(coeffs{1}, 0, AbsTol=1e-10);
    testCase.verifyEqual(coeffs{2}, 0, AbsTol=1e-10);
    testCase.verifyEqual(coeffs{3}, 4, AbsTol=1e-10);
end

function testFunDegUseForAlp(testCase)
    % Each cell should order fitted controls from its physical lower to
    % upper face.
    A = pdmat({[-2 0.5 4]}, @(rho) rho.^2, Degree=2);
    first = A.coeffs(1);
    second = A.coeffs(2);

    testCase.verifyEqual(A.Degree, 2);
    testCase.verifyEqual([first{:}], [4, -1, 0.25], AbsTol=1e-10);
    testCase.verifyEqual([second{:}], [0.25, 2, 16], AbsTol=1e-10);
end

function testNumFalMatPol(testCase)
    % Numeric fallback should certify matrix polynomials on every cell.
    A = pdmat({[0 0.4 1]}, @numericOnlyMatrixPolynomial, Degree=2);

    first = A.coeffs(1);
    second = A.coeffs(2);
    testCase.verifyEqual(first, {
        [0, 0; 1, 2], ...
        [0, 0.2; 1, 2], ...
        [0.16, 0.4; 1, 2]
        }, AbsTol=1e-10);
    testCase.verifyEqual(second, {
        [0.16, 0.4; 1, 2], ...
        [0.4, 0.7; 1, 2], ...
        [1, 1; 1, 2]
        }, AbsTol=1e-10);
end

function testScaGriVecSho(testCase)
    % A plain numeric vector is accepted as the one-parameter grid.
    A = pdmat([0 1 2], {10, 20, 30}, Degree=1);

    testCase.verifyEqual(A.Degree, 1);
    testCase.verifyEqual(A.GridInfo.Vectors, {[0 1 2]});
    testCase.verifyEqual(A.coeffs(2), {20, 30});
end

function testFunDoeNotSamWho(testCase)
    % Function-only construction should probe size without sampling every
    % node.
    A = pdmat({[0 1 2]}, @lowerOnly);

    testCase.verifyEqual(A.Degree, 1);
    testCase.verifyEqual(A.MatrixSize, [1 2]);
    testCase.verifyEqual(A.SourceSummary, "function");
    testCase.verifyEqual(A.coeffs(2), {zeros(1, 2), zeros(1, 2)});
end

function testGloDegTwoSca(testCase)
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

function testTenGloCelGri(testCase)
    % Tensor global cell data should preserve grid metadata and local
    % order.
    data = cell(3, 2);
    for i = 1:3
        for j = 1:2
            data{i, j} = [i, j];
        end
    end

    A = pdmat({[0 1 2], [10 20]}, data, Degree=[1 1]);

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

function testAniMulCelMatGri(testCase)
    % Public global-grid construction must retain every anisotropic matrix
    % coefficient and every shared physical face in two and three parameters.
    cases = {
        {[0 1 3], [-2 0 4]}, [2 1], [2 3]
        {[0 1 3], [-2 0 4], [10 15]}, [1 2 1], [2 2]
        };

    for k = 1:size(cases, 1)
        grid = cases{k, 1};
        deg = cases{k, 2};
        sz = cases{k, 3};
        data = makeGridMats(grid, deg, sz);
        A = constructWarningFree(testCase, ...
            @() pdmat(grid, data, Degree=deg));

        testCase.verifyEqual(A.Degree, deg);
        testCase.verifyEqual(A.MatrixSize, sz);
        testCase.verifyTrue(A.IsContinuous);
        verifyGridMap(testCase, A, data);
        verifySharedFaces(testCase, A);
    end
end

function testExpNesLocVal(testCase)
    % Misaligned nested LocalValues should warn without changing their
    % data.
    localValues = {
        {mkCoeff(100)}, ...
        {mkCoeff(200)}
        };

    A = constructWithWarning(testCase, ...
        @() pdmat({[0 1 2], [10 20]}, localValues), ...
        "pdmat:DiscontinuousLocalValues");

    testCase.verifyEqual(A.Degree, [1 1]);
    testCase.verifyEqual(A.MatrixSize, [1 2]);
    testCase.verifyFalse(A.IsContinuous);
    testCase.verifyEqual(A.LocalValues{1}{1}, mkCoeff(100));
    testCase.verifyEqual(A.LocalValues{2}{1}, mkCoeff(200));
    testCase.verifyEqual(A.coeffs([1 1]), mkCoeff(100));
end

function testTwoDimGloBerDat(testCase)
    % A 3-by-3 global degree-one grid should share faces in both
    % directions.
    grid = {[0 1 2], [10 20 30]};
    data = cell(3, 3);
    for i = 1:3
        for j = 1:3
            data{i, j} = 10 * i + j;
        end
    end

    A = constructWarningFree(testCase, @() pdmat(grid, data, Degree=[1 1]));
    c11 = A.coeffs([1 1]);
    c21 = A.coeffs([2 1]);
    c12 = A.coeffs([1 2]);

    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyEqual(c11, {11, 12, 21, 22});
    testCase.verifyEqual(A.coeffs([2 2]), {22, 23, 32, 33});
    testCase.verifyEqual(c11([3 4]), c21([1 2]));
    testCase.verifyEqual(c11([2 4]), c12([1 3]));
end

function testTwoDimAliNesLoc(testCase)
    % Explicit tensor local values remain continuous when every face
    % agrees.
    grid = {[0 1 2], [10 20 30]};
    localValues = mkAliDloVal();

    A = constructWarningFree(testCase, ...
        @() pdmat(grid, localValues, Degree=[1 1]));

    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyEqual(A.LocalValues{2}{1}, {21, 22, 31, 32});
    testCase.verifyEqual(A.LocalValues{1}{2}, {12, 13, 22, 23});
    testCase.verifyEqual(A.coeffs([1 1]), {11, 12, 21, 22});
end

function testNesLocValConTol(testCase)
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

function testScaDegWarAndSil(testCase)
    % Only explicit multidimensional scalar Degree uses the expansion
    % warning.
    grid = {[0 1], [10 20]};
    data = {1 2; 3 4};

    explicit = constructWithWarning(testCase, ...
        @() pdmat(grid, data, Degree=1), ...
        "pdmat:ScalarDegreeExpansion");
    inferred = constructWarningFree(testCase, @() pdmat(grid, data));
    functionOnly = constructWarningFree(testCase, ...
        @() pdmat(grid, @(rho, eta) rho + eta));
    oneDimensional = constructWarningFree(testCase, ...
        @() pdmat([0 1], {1, 2}, Degree=1));

    testCase.verifyEqual(explicit.Degree, [1 1]);
    testCase.verifyEqual(inferred.Degree, [1 1]);
    testCase.verifyEqual(functionOnly.Degree, [1 1]);
    testCase.verifyEqual(oneDimensional.Degree, 1);
end

function testAniGloInfAndNes(testCase)
    % Global shape infers each axis; flat nested leaves need explicit
    % vectors.
    grid = {[0 0.5 1], [10 20]};
    globalData = cell(3, 4);
    for i = 1:3
        for j = 1:4
            globalData{i, j} = 10 * i + j;
        end
    end

    inferred = constructWarningFree(testCase, @() pdmat(grid, globalData));
    testCase.verifyEqual(inferred.Degree, [1 3]);
    testCase.verifyEqual(inferred.ncoeff(), 8);
    testCase.verifyEqual(inferred.coeffs([2 1]), ...
        {21, 22, 23, 24, 31, 32, 33, 34});

    nested = {{{1, 2, 3, 4, 5, 6}}};
    explicit = constructWarningFree(testCase, ...
        @() pdmat({[0 1], [10 20]}, nested, Degree=[1; 2]));
    testCase.verifyEqual(explicit.Degree, [1 2]);
    testCase.verifyEqual(explicit.coeffs([1 1]), nested{1}{1});

    testCase.verifyError(@() pdmat({[0 1], [10 20]}, nested), ...
        "pdmat:InvalidDegree");
end

function testGloHigDimAndExtDimVal(testCase)
    % Global grids accept implicit singleton axes and reject extra data axes.
    grid = {[0 1], [10 20], [100 200]};
    A = pdmat(grid, {1, 2; 3, 4}, Degree=[1 1 0]);

    testCase.verifyEqual(A.Degree, [1 1 0]);
    testCase.verifyEqual(A.coeffs([1 1 1]), {1, 2, 3, 4});

    bad = reshape(num2cell(1:8), [2 2 2]);
    testCase.verifyError(@() pdmat({[0 1], [10 20]}, bad), ...
        "pdmat:InvalidData");
end

function c = mkCoeff(offset)
    % Keep matrix payloads distinct while preserving flat coefficient
    % order.
    c = {
        [offset + 1, offset + 2], ...
        [offset + 3, offset + 4], ...
        [offset + 5, offset + 6], ...
        [offset + 7, offset + 8]
        };
end

function vals = mkAliDloVal()
    % Keep tensor labels ordered as [0 0], [0 1], [1 0], [1 1].
    vals = {
        {{11, 12, 21, 22}, {12, 13, 22, 23}}, ...
        {{21, 22, 31, 32}, {22, 23, 32, 33}}
        };
end

function data = makeGridMats(grid, deg, sz)
    % Give every global tensor label a distinct rectangular/square payload.
    dims = (cellfun(@numel, grid) - 1) .* deg + 1;
    data = cell(dims);
    nPar = numel(grid);
    for k = 1:numel(data)
        subs = cell(1, nPar);
        [subs{:}] = ind2sub(dims, k);
        key = sum((cell2mat(subs) - 1) .* 10 .^ (0:(nPar - 1)));
        data{k} = reshape(key + (1:prod(sz)), sz);
    end
end

function verifyGridMap(testCase, A, data)
    % Compare every local coefficient label with its global-grid source entry.
    labels = labelRowsExpected(A.Degree);
    cells = A.cells();
    for c = 1:size(cells, 1)
        leaf = A.coeffs(cells(c, :));
        for k = 1:size(labels, 1)
            idx = (cells(c, :) - 1) .* A.Degree + labels(k, :) + 1;
            subs = num2cell(idx);
            testCase.verifyEqual(leaf{k}, data{subs{:}}, AbsTol=0);
        end
    end
end

function verifySharedFaces(testCase, A)
    % Adjacent cells must expose the same complete matrix face in every axis.
    labels = labelRowsExpected(A.Degree);
    cells = A.cells();
    nCell = A.GridInfo.NumNodes - 1;
    for c = 1:size(cells, 1)
        for dim = 1:numel(A.Degree)
            if cells(c, dim) >= nCell(dim) || A.Degree(dim) == 0
                continue
            end
            next = cells(c, :);
            next(dim) = next(dim) + 1;
            left = A.coeffs(cells(c, :));
            right = A.coeffs(next);
            face = find(labels(:, dim) == A.Degree(dim));
            for k = reshape(face, 1, [])
                other = labels(k, :);
                other(dim) = 0;
                j = find(all(labels == other, 2), 1);
                testCase.verifyEqual(left{k}, right{j}, AbsTol=0);
            end
        end
    end
end

function rows = labelRowsExpected(deg)
    % Enumerate tensor labels independently with the last axis varying fastest.
    rows = (0:deg(1)).';
    for dim = 2:numel(deg)
        next = (0:deg(dim)).';
        rows = [repelem(rows, numel(next), 1), ...
            repmat(next, size(rows, 1), 1)]; %#ok<AGROW>
    end
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
    % Guard that function-backed construction probes only the lower grid
    % point.
    if rho ~= 0
        error("test:UnexpectedSample", "Constructor should only probe the lower point.");
    end
    out = [1 2];
end

function out = numericOnlyMatrixPolynomial(rho)
    % Force numeric fallback while retaining exact matrix-polynomial data.
    if ~isnumeric(rho)
        error("test:NoSymbolicPath", "Use numeric fallback.");
    end
    out = [rho.^2, rho; 1, 2];
end
