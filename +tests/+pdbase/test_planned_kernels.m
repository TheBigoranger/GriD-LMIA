function tests = test_planned_kernels
    %TEST_PLANNED_KERNELS Independent product and elevation formula checks.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep symbolic bases and variable identifiers local to this suite.
    yalmip("clear");
end

function testNumThrParUneDeg(testCase)
    % A multi-cell 3-D matrix product must match the direct Bernstein sum.
    grid = {[0 0.5 1], [10 20], [-2 3]};
    leftDegree = [2 1 0];
    rightDegree = [1 0 2];
    leftValues = numericTree(grid, leftDegree, [2 3], 10);
    rightValues = numericTree(grid, rightDegree, [3 2], 100);
    A = pdmat(grid, leftValues, Degree=leftDegree);
    B = pdmat(grid, rightValues, Degree=rightDegree);

    C = A * B;

    testCase.verifyEqual(C.Degree, leftDegree + rightDegree);
    testCase.verifyEqual(C.GridInfo.Vectors, grid);
    testCase.verifyEqual(C.MatrixSize, [2 2]);
    cells = C.cells();
    for cellIndex = 1:size(cells, 1)
        subs = cells(cellIndex, :);
        expected = legacyBernProduct(A.coeffs(subs), leftDegree, ...
            B.coeffs(subs), rightDegree, 3);
        verifyCoefficientRow(testCase, C.coeffs(subs), expected, 1e-11);
    end
end

function testKnoAffBloConBot(testCase)
    % Planned contractions retain exact affine bases and multiplication order.
    grid = {[0 1], [10 20]};
    knownData = cell(3, 3);
    for row = 1:3
        for col = 1:3
            knownData{row, col} = [row, col; row + col, row - col];
        end
    end
    A = pdmat(grid, knownData, Degree=[2 2]);
    P = pdvar(2, grid, "full", Degree=[1 1]);
    knownCoeffs = A.coeffs([1 1]);
    affineCoeffs = P.coeffs([1 1]);

    leftActual = A * P;
    rightActual = P * A;
    leftExpected = legacyBernProduct(knownCoeffs, 2, ...
        affineCoeffs, 1, 2);
    rightExpected = legacyBernProduct(affineCoeffs, 1, ...
        knownCoeffs, 2, 2);

    verifyAffineRow(testCase, leftActual.coeffs([1 1]), leftExpected);
    verifyAffineRow(testCase, rightActual.coeffs([1 1]), rightExpected);
    testCase.verifyEqual(objectVariables(leftActual), objectVariables(P));
    testCase.verifyEqual(objectVariables(rightActual), objectVariables(P));
end

function testNumAndSymTenEle(testCase)
    % Sparse elevation operators must equal the independent incidence formula.
    numericGrid = {[0 1], [10 20], [-1 1]};
    sourceMatrix = [1 2; 3 5];
    numericValues = helper.mkNest([1 1 1], @(~) {sourceMatrix});
    numeric = pdbase(numericGrid, [2 2], 0, numericValues);

    numericElevated = numeric.elevate(3);
    numericExpected = legacyElevate({sourceMatrix}, 0, 3, 3);
    verifyCoefficientRow(testCase, ...
        numericElevated.coeffs([1 1 1]), numericExpected, 1e-13);

    symbolic = pdvar(2, {[0 1], [10 20]}, "full", Degree=[1 1]);
    symbolicVars = objectVariables(symbolic);
    symbolicElevated = symbolic.elevate(2);
    symbolicExpected = legacyElevate(symbolic.coeffs([1 1]), 1, 3, 2);

    verifyAffineRow(testCase, ...
        symbolicElevated.coeffs([1 1]), symbolicExpected);
    testCase.verifyEqual(objectVariables(symbolicElevated), symbolicVars);
end

function testTenRatRowEleInd(testCase)
    % Every rate vertex uses the same map without mixing coefficient rows.
    nParameters = 2;
    sourceDegree = 1;
    targetDegree = 3;
    sourceCount = (sourceDegree + 1) ^ nParameters;
    leaf = cell(2 ^ nParameters, sourceCount);
    for row = 1:size(leaf, 1)
        for coefficient = 1:size(leaf, 2)
            leaf{row, coefficient} = 100 * row + coefficient;
        end
    end
    values = helper.mkNest([1 1], @(~) leaf);
    obj = pdbase({[0 1], [10 20]}, [1 1], sourceDegree, values, ...
        RateBounds=[-1 1; -2 3]);

    elevated = obj.elevate(targetDegree - sourceDegree);
    actual = elevated.coeffs([1 1]);

    testCase.verifySize(actual, [4, 16]);
    for row = 1:size(leaf, 1)
        expected = legacyElevate(leaf(row, :), ...
            sourceDegree, targetDegree, nParameters);
        verifyCoefficientRow(testCase, actual(row, :), expected, 1e-13);
    end
end

function testNumEleKeeDenCoe(testCase)
    % A sparse plan is internal metadata; numeric payloads remain dense.
    source = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);

    elevated = source.elevate(3);
    coefficients = elevated.coeffs(1);

    testCase.verifyTrue(all(cellfun(@isnumeric, coefficients)));
    testCase.verifyFalse(any(cellfun(@issparse, coefficients)));
end

function testHighDegreeConstantKernels(testCase)
    % Degree 1030 must remain finite after product and elevation planning.
    coeffs = repmat({1}, 1, 516);
    factor = pdmat({[0 1]}, coeffs, Degree=515);

    product = factor * factor;
    productValues = cell2mat(product.coeffs(1));
    testCase.verifyTrue(all(isfinite(productValues)));
    testCase.verifyLessThanOrEqual(max(abs(productValues - 1)), 1e-10);

    constant = pdmat({[0 1]}, {1}, Degree=0);
    elevated = constant.elevate(1030);
    elevatedValues = cell2mat(elevated.coeffs(1));
    testCase.verifyTrue(all(isfinite(elevatedValues)));
    testCase.verifyLessThanOrEqual(max(abs(elevatedValues - 1)), 1e-10);
end

function values = numericTree(grid, degree, matrixSize, offset)
    % Build deterministic nested local data on every physical tensor cell.
    nCell = cellfun(@numel, grid) - 1;
    degree = expandDegree(degree, numel(grid));
    labels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, degree, ...
        "UniformOutput", false));
    values = helper.mkNest(nCell, @makeLeaf);

    function leaf = makeLeaf(subs)
        leaf = cell(1, size(labels, 1));
        for coefficient = 1:numel(leaf)
            globalLabel = (subs - 1) .* degree + labels(coefficient, :);
            base = offset + 10 * sum(globalLabel .* 10 .^ (0:numel(degree) - 1));
            leaf{coefficient} = reshape( ...
                base + (1:prod(matrixSize)), matrixSize);
        end
    end
end

function out = legacyBernProduct(lhs, lhsDegree, rhs, rhsDegree, nParameters)
    % Direct pair-sum oracle independent of product-plan implementation.
    lhsDegree = expandDegree(lhsDegree, nParameters);
    rhsDegree = expandDegree(rhsDegree, nParameters);
    outputDegree = lhsDegree + rhsDegree;
    lhsLabels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, lhsDegree, ...
        "UniformOutput", false));
    outputLabels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, ...
        outputDegree, "UniformOutput", false));
    out = cell(1, size(outputLabels, 1));
    for outputIndex = 1:size(outputLabels, 1)
        outputLabel = outputLabels(outputIndex, :);
        accumulator = [];
        for lhsIndex = 1:size(lhsLabels, 1)
            lhsLabel = lhsLabels(lhsIndex, :);
            rhsLabel = outputLabel - lhsLabel;
            if any(rhsLabel < 0) || any(rhsLabel > rhsDegree)
                continue
            end
            rhsIndex = labelIndex(rhsLabel, rhsDegree);
            scale = productScale(lhsLabel, lhsDegree, ...
                rhsLabel, rhsDegree, outputLabel);
            term = (lhs{lhsIndex} * rhs{rhsIndex}) .* scale;
            if isempty(accumulator)
                accumulator = term;
            else
                accumulator = accumulator + term;
            end
        end
        out{outputIndex} = accumulator;
    end
end

function out = legacyElevate(source, sourceDegree, targetDegree, nParameters)
    % Direct source-to-target incidence oracle for Bernstein elevation.
    sourceDegree = expandDegree(sourceDegree, nParameters);
    targetDegree = expandDegree(targetDegree, nParameters);
    sourceLabels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, ...
        sourceDegree, "UniformOutput", false));
    targetLabels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, ...
        targetDegree, "UniformOutput", false));
    gap = targetDegree - sourceDegree;
    out = cell(1, size(targetLabels, 1));
    for targetIndex = 1:size(targetLabels, 1)
        targetLabel = targetLabels(targetIndex, :);
        accumulator = [];
        for sourceIndex = 1:size(sourceLabels, 1)
            sourceLabel = sourceLabels(sourceIndex, :);
            delta = targetLabel - sourceLabel;
            if any(delta < 0) || any(delta > gap)
                continue
            end
            scale = 1;
            for parameter = 1:nParameters
                scale = scale ...
                    * nchoosek(sourceDegree(parameter), sourceLabel(parameter)) ...
                    * nchoosek(gap(parameter), delta(parameter)) ...
                    / nchoosek(targetDegree(parameter), targetLabel(parameter));
            end
            term = source{sourceIndex} .* scale;
            if isempty(accumulator)
                accumulator = term;
            else
                accumulator = accumulator + term;
            end
        end
        out{targetIndex} = accumulator;
    end
end

function scale = productScale(lhsLabel, lhsDegree, rhsLabel, ...
        rhsDegree, outputLabel)
    % Return the tensor Bernstein product normalization.
    outputDegree = lhsDegree + rhsDegree;
    scale = 1;
    for parameter = 1:numel(outputLabel)
        scale = scale ...
            * nchoosek(lhsDegree(parameter), lhsLabel(parameter)) ...
            * nchoosek(rhsDegree(parameter), rhsLabel(parameter)) ...
            / nchoosek(outputDegree(parameter), outputLabel(parameter));
    end
end

function index = labelIndex(label, degree)
    % Convert repository mixed-radix label order to a one-based index.
    multipliers = fliplr(cumprod([1, fliplr(degree(2:end) + 1)]));
    index = label * multipliers' + 1;
end

function degree = expandDegree(degree, nParameters)
    % Expand scalar shorthand without sharing production normalizer logic.
    degree = reshape(degree, 1, []);
    if isscalar(degree)
        degree = repmat(degree, 1, nParameters);
    end
end

function verifyCoefficientRow(testCase, actual, expected, tolerance)
    % Compare numeric coefficient rows without loosening tensor indexing.
    testCase.verifyEqual(size(actual), size(expected));
    for coefficient = 1:numel(actual)
        scale = max(1, norm(expected{coefficient}, "fro"));
        testCase.verifyLessThanOrEqual( ...
            norm(actual{coefficient} - expected{coefficient}, "fro"), ...
            tolerance * scale);
    end
end

function verifyAffineRow(testCase, actual, expected)
    % Compare YALMIP variable identities and complete affine base matrices.
    testCase.verifyEqual(size(actual), size(expected));
    for coefficient = 1:numel(actual)
        testCase.verifyEqual(getvariables(actual{coefficient}), ...
            getvariables(expected{coefficient}));
        difference = actual{coefficient} - expected{coefficient};
        base = full(getbase(difference));
        testCase.verifyLessThanOrEqual(norm(base, "fro"), ...
            128 * eps(max(1, norm(full(getbase(expected{coefficient})), "fro"))));
    end
end

function variables = objectVariables(obj)
    % Collect unique decision identifiers across cells, rows, and coefficients.
    variables = [];
    cells = obj.cells();
    for cellIndex = 1:size(cells, 1)
        coeffs = obj.coeffs(cells(cellIndex, :));
        for coefficient = 1:numel(coeffs)
            if isa(coeffs{coefficient}, "sdpvar")
                variables = [variables, ...
                    getvariables(coeffs{coefficient})]; %#ok<AGROW>
            end
        end
    end
    variables = unique(variables);
end
