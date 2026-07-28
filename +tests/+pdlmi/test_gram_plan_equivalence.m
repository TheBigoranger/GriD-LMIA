function tests = test_gram_plan_equivalence
    %TEST_GRAM_PLAN_EQUIVALENCE Compare planned maps to the legacy double loop.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    yalmip("clear");
end

function testDenseOneDimensionalFullBox(testCase)
    residual = pdvar(2, {[0 1]}, "symmetric", Degree=2);
    direct = residual >= 0;
    actual = direct.applyFullBoxPreorder(1);
    [targetDegree, specs] = fullBoxSpecs(1, residual.Degree, 1);

    verifyLegacyCertificate(testCase, actual, targetDegree, specs, []);
end

function testMultidimensionalPutinar(testCase)
    grid = {[0 1], [-1 1]};
    residual = pdvar(2, grid, "symmetric", Degree=2);
    direct = residual >= 0;
    actual = direct.applyPutinar(1);
    specs = putinarSpecs(2, 1);

    verifyLegacyCertificate(testCase, actual, 2, specs, []);
end

function testSparseTensorWindows(testCase)
    grid = {[0 1], [-1 1]};
    residual = pdvar(1, grid, Degree=2);
    direct = residual >= 0;
    actual = direct.applySparseFullBoxPreorder(2, 2);
    [targetDegree, specs] = fullBoxSpecs(2, residual.Degree, 2);

    verifyLegacyCertificate(testCase, actual, targetDegree, specs, 2);
end

function verifyLegacyCertificate(testCase, wrapper, targetDegree, specs, bandWidth)
    % Rebuild one local certificate from the actual Gram variables.
    nPar = numel(wrapper.Residual.GridInfo.Vectors);
    targetDegreeVector = targetDegree * ones(1, nPar);
    maps = expandMaps(specs, nPar, bandWidth);
    targetCount = prod(targetDegreeVector + 1);
    testCase.verifyEqual(numel(wrapper.Constraints), ...
        numel(maps) + targetCount);

    reference = cell(size(wrapper.Constraints));
    matrixSize = wrapper.Residual.MatrixSize(1);
    represented = repmat({zeros(matrixSize)}, 1, targetCount);
    for block = 1:numel(maps)
        reference{block} = wrapper.Constraints{block};
        gram = sdpvar(wrapper.Constraints{block});
        term = legacyBernGramCoeffs(gram, maps{block}.GramDegree, ...
            maps{block}.AlphaPower, maps{block}.OneMinusAlphaPower, ...
            maps{block}.BasisLabels);
        for coefficient = 1:targetCount
            represented{coefficient} = represented{coefficient} + ...
                term{coefficient};
        end
    end

    values = wrapper.Residual.elevVals( ...
        targetDegree - wrapper.Residual.Degree);
    cells = wrapper.Residual.cells();
    target = helper.cellGet(values, cells(1, :));
    target = target(1, :);
    if wrapper.Relation == "<="
        target = cellfun(@uminus, target, "UniformOutput", false);
    end
    for coefficient = 1:targetCount
        reference{numel(maps) + coefficient} = ...
            represented{coefficient} == target{coefficient};
    end

    verifyConstraintCells(testCase, wrapper.Constraints, reference);
    verifyExportCones(testCase, wrapper.Constraints, reference);
end

function maps = expandMaps(specs, nPar, bandWidth)
    %EXPANDMAPS Independently enumerate legacy dense/window block order.
    maps = {};
    for specIndex = 1:size(specs, 1)
        gramDegree = reshape(specs{specIndex, 1}, 1, []);
        if any(gramDegree < 0)
            continue
        end
        weight = specs{specIndex, 2};
        alphaPower = reshape(weight(1, :), 1, nPar);
        oneMinusAlphaPower = reshape(weight(2, :), 1, nPar);
        if isempty(bandWidth)
            basisLabels = labelRows(gramDegree);
            maps{end + 1, 1} = mapRecord(gramDegree, ...
                alphaPower, oneMinusAlphaPower, basisLabels); %#ok<AGROW>
        else
            windowSize = min(bandWidth, gramDegree + 1);
            localLabels = labelRows(windowSize - 1);
            starts = labelRows(gramDegree - windowSize + 1);
            for window = 1:size(starts, 1)
                basisLabels = localLabels + starts(window, :);
                maps{end + 1, 1} = mapRecord(gramDegree, ...
                    alphaPower, oneMinusAlphaPower, basisLabels); %#ok<AGROW>
            end
        end
    end
end

function map = mapRecord(gramDegree, alphaPower, oneMinusAlphaPower, basisLabels)
    map = struct( ...
        GramDegree=gramDegree, ...
        AlphaPower=alphaPower, ...
        OneMinusAlphaPower=oneMinusAlphaPower, ...
        BasisLabels=basisLabels);
end

function coeffs = legacyBernGramCoeffs(gram, gramDegree, ...
        alphaPower, oneMinusAlphaPower, basisLabels)
    %LEGACYBERNGRAMCOEFFS Preserve the pre-plan double-loop oracle.
    nPar = numel(gramDegree);
    nBasis = size(basisLabels, 1);
    matrixSize = size(gram, 1) / nBasis;
    targetDegree = 2 * gramDegree + alphaPower + oneMinusAlphaPower;
    targetLabels = labelRows(targetDegree);
    coeffs = repmat({zeros(matrixSize)}, 1, size(targetLabels, 1));
    for left = 1:nBasis
        leftBlock = (left - 1) * matrixSize + (1:matrixSize);
        for right = 1:nBasis
            rightBlock = (right - 1) * matrixSize + (1:matrixSize);
            label = basisLabels(left, :) + basisLabels(right, :) + ...
                alphaPower;
            [~, output] = ismember(label, targetLabels, "rows");
            scale = 1;
            for parameter = 1:nPar
                scale = scale ...
                    * nchoosek(gramDegree(parameter), ...
                        basisLabels(left, parameter)) ...
                    * nchoosek(gramDegree(parameter), ...
                        basisLabels(right, parameter)) ...
                    / nchoosek(targetDegree(parameter), label(parameter));
            end
            coeffs{output} = coeffs{output} + ...
                scale * gram(leftBlock, rightBlock);
        end
    end
end

function [targetDegree, specs] = fullBoxSpecs(nPar, degree, order)
    %FULLBOXSPECS Independent copy of the public certificate convention.
    if nPar == 1 && mod(degree, 2) == 1
        targetDegree = 2 * order + 1;
        specs = {order, [0; 1]; order, [1; 0]};
    elseif nPar == 1
        targetDegree = 2 * order;
        specs = {order, [0; 0]};
        if order > 0
            specs(end + 1, :) = {order - 1, [1; 1]};
        end
    else
        targetDegree = 2 * order;
        masks = helper.combRows(repmat({0:1}, 1, nPar));
        specs = cell(size(masks, 1), 2);
        for k = 1:size(masks, 1)
            specs{k, 1} = order - masks(k, :);
            specs{k, 2} = [masks(k, :); masks(k, :)];
        end
    end
end

function specs = putinarSpecs(nPar, order)
    %PUTINARSPECS Independent multidimensional singleton-generator form.
    masks = [zeros(1, nPar); eye(nPar)];
    specs = cell(size(masks, 1), 2);
    for k = 1:size(masks, 1)
        specs{k, 1} = order * ones(1, nPar) - masks(k, :);
        specs{k, 2} = [masks(k, :); masks(k, :)];
    end
end

function rows = labelRows(maxLabel)
    ranges = arrayfun(@(degree) 0:degree, maxLabel, ...
        "UniformOutput", false);
    rows = helper.combRows(ranges);
end

function verifyConstraintCells(testCase, actual, reference)
    testCase.verifyEqual(numel(actual), numel(reference));
    for k = 1:numel(actual)
        testCase.verifyEqual(is(actual{k}, "equality"), ...
            is(reference{k}, "equality"));
        testCase.verifyEqual(is(actual{k}, "sdp"), is(reference{k}, "sdp"));
        testCase.verifyEqual(getvariables(actual{k}), ...
            getvariables(reference{k}));
        actualExpression = sdpvar(actual{k});
        referenceExpression = sdpvar(reference{k});
        testCase.verifySize(actualExpression, size(referenceExpression));
        scale = max(1, norm(full(getbase(referenceExpression)), "fro"));
        testCase.verifyLessThanOrEqual( ...
            norm(full(getbase(actualExpression)) - ...
                full(getbase(referenceExpression)), "fro"), ...
            512 * eps(scale));
    end
end

function verifyExportCones(testCase, actual, reference)
    actualConstraints = [actual{:}];
    referenceConstraints = [reference{:}];
    originalPath = path;
    cleanup = onCleanup(@() restorePath(originalPath));
    addpath(fileparts(which("yalmip")), "-begin");
    clear export
    settings = sdpsettings;
    settings.solver = 'sedumi';
    settings.verbose = 0;
    actualModel = export(actualConstraints, [], settings);
    referenceModel = export(referenceConstraints, [], settings);
    testCase.verifyEqual(actualModel.K.f, referenceModel.K.f);
    testCase.verifyEqual(actualModel.K.l, referenceModel.K.l);
    testCase.verifyEqual(actualModel.K.s, referenceModel.K.s);
    clear export
end

function restorePath(originalPath)
    path(originalPath);
    clear export
end
