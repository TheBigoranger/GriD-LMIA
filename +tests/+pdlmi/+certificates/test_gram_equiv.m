function tests = test_gram_equiv
    % Behavioral regressions for pdlmi.gram_equiv.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    yalmip("clear");
end

function test_interval_full_box_identity(testCase)
    residual = pdvar(2, {[0 1]}, "symmetric", Degree=2);
    direct = residual >= 0;
    actual = direct.useFullBox(1);
    [targetDegree, specs] = fullBoxSpecs(1, residual.Degree, 1);

    veriLegCer(testCase, actual, targetDegree, specs, []);
end

function test_tensor_putinar_identity(testCase)
    grid = {[0 1], [-1 1]};
    residual = pdvar(2, grid, "symmetric", Degree=[2 2]);
    direct = residual >= 0;
    actual = direct.usePutinar(1);
    specs = putinarSpecs(2, 1);

    veriLegCer(testCase, actual, 2, specs, []);
end

function test_sparse_tensor_window_identity(testCase)
    grid = {[0 1], [-1 1]};
    residual = pdvar(1, grid, Degree=[2 2]);
    direct = residual >= 0;
    actual = direct.useSpBox(2, 2);
    [targetDegree, specs] = fullBoxSpecs(2, residual.Degree, 2);

    veriLegCer(testCase, actual, targetDegree, specs, 2);
end

function test_unequal_tensor_orders_preserve_legacy_coefficient(testCase)
    % Unequal tensor orders must preserve the legacy coefficient-map oracle.
    grid = {[0 1], [-1 1]};
    residual = pdvar(1, grid, Degree=[1 4]);
    direct = residual >= 0;
    actual = direct.useFullBox([1 2]);
    [targetDegree, specs] = fullBoxSpecs( ...
        2, residual.Degree, [1 2]);

    veriLegCer(testCase, actual, targetDegree, specs, []);
end

function test_negative_mask_degrees_omitted_either_zero(testCase)
    % Negative mask degrees are omitted for either zero-degree axis.
    grid = {[0 1], [-1 1]};
    residual = pdvar(1, grid, Degree=[0 2]);
    direct = residual >= 0;
    actual = direct.usePutinar([0 1]);
    veriLegCer(testCase, actual, [0 2], ...
        putinarSpecs(2, [0 1]), []);

    reversed = pdvar(1, grid, Degree=[2 0]);
    reversedDirect = reversed >= 0;
    reversedActual = reversedDirect.usePutinar([1 0]);
    veriLegCer(testCase, reversedActual, [2 0], ...
        putinarSpecs(2, [1 0]), []);
end

function test_scalar_windows_operate_axis_anisotropic_gram(testCase)
    % Scalar windows operate on per-axis anisotropic Gram cardinalities.
    grid = {[0 1], [-1 1]};
    residual = pdvar(1, grid, Degree=[2 6]);
    direct = residual >= 0;
    actual = direct.useSpBox(2, [1 3]);
    [targetDegree, specs] = fullBoxSpecs( ...
        2, residual.Degree, [1 3]);

    veriLegCer(testCase, actual, targetDegree, specs, 2);
end

function test_sparseputinar_singleton_masks_legacy_tensor_window(testCase)
    % SparsePutinar uses singleton masks with the legacy tensor-window map.
    grid = {[0 1], [-1 1]};
    residual = pdvar(1, grid, Degree=[2 6]);
    direct = residual >= 0;
    actual = direct.useSpPut(2, [1 3]);
    specs = putinarSpecs(2, [1 3]);

    veriLegCer(testCase, actual, [2 6], specs, 2);
end

function veriLegCer(testCase, wrapper, targetDegree, specs, bandWidth, entrywise)
    % Rebuild every cell/rate/entry certificate using independent binomial sums.
    if nargin < 6, entrywise = false; end
    degree = wrapper.Residual.Degree;
    nPar = numel(degree);
    targetDegree = expandDegree(targetDegree, nPar);
    maps = expandMaps(specs, nPar, bandWidth);
    targetCount = prod(targetDegree+1);
    cells = tests.infrastructure.labels(wrapper.Residual.GridInfo.NumNodes-2)+1;
    reference = cell(size(wrapper.Constraints));
    offset = 0;
    used = [];
    for cellIndex = 1:size(cells,1)
        target = tests.infrastructure.elevate(wrapper.Residual.coeffs(cells(cellIndex,:)), degree, targetDegree);
        if wrapper.Relation == "<=", target=cellfun(@uminus,target,'UniformOutput',false); end
        if entrywise, count=prod(wrapper.Residual.MatrixSize); sz=1;
        else, count=1; sz=wrapper.Residual.MatrixSize(1); end
        for row = 1:size(target,1)
            for entry = 1:count
                represented = repmat({zeros(sz)},1,targetCount);
                for block = 1:numel(maps)
                    index=offset+block;
                    cone=wrapper.Constraints{index};
                    gram=sdpvar(cone);
                    testCase.verifyEqual(logical(is(cone,'sdp')),size(gram,1)>1);
                    testCase.verifySize(gram,[sz sz]*size(maps{block}.BasisLabels,1));
                    ids=getvariables(gram);
                    testCase.verifyEmpty(intersect(used,ids));
                    testCase.verifyEmpty(intersect(ids,getvariables([target{row,:}])));
                    used=[used ids]; %#ok<AGROW>
                    reference{index}=gram>=0;
                    term=legacyBernGramCoeffs(gram,maps{block}.GramDegree, ...
                        maps{block}.AlphaPower,maps{block}.OneMinusAlphaPower,maps{block}.BasisLabels);
                    for k=1:targetCount, represented{k}=represented{k}+term{k}; end
                end
                for k=1:targetCount
                    rhs=target{row,k};
                    if entrywise, rhs=rhs(entry); end
                    reference{offset+numel(maps)+k}=represented{k}==rhs;
                end
                offset=offset+numel(maps)+targetCount;
            end
        end
    end
    testCase.verifyEqual(offset,numel(wrapper.Constraints));
    veriConCel(testCase,wrapper.Constraints,reference);
    verifyExportCones(testCase,wrapper.Constraints,reference);
end

function [targetDegree, specs] = fullBoxSpecs(nPar, degree, order)
    %FULLBOXSPECS Independent copy of the public certificate convention.
    degree = expandDegree(degree, nPar);
    order = expandDegree(order, nPar);
    if nPar == 1 && mod(degree(1), 2) == 1
        targetDegree = 2 * order + 1;
        specs = {order, [0; 1]; order, [1; 0]};
    elseif nPar == 1
        targetDegree = 2 * order;
        specs = {order, [0; 0]};
        if order(1) > 0
            specs(end + 1, :) = {order - 1, [1; 1]};
        end
    else
        targetDegree = 2 * order;
        masks = tests.infrastructure.labels(ones(1,nPar));
        specs = cell(size(masks, 1), 2);
        for k = 1:size(masks, 1)
            specs{k, 1} = order - masks(k, :);
            specs{k, 2} = [masks(k, :); masks(k, :)];
        end
    end
end

function specs = putinarSpecs(nPar, order)
    %PUTINARSPECS Independent multidimensional singleton-generator form.
    order = expandDegree(order, nPar);
    masks = [zeros(1, nPar); eye(nPar)];
    specs = cell(size(masks, 1), 2);
    for k = 1:size(masks, 1)
        specs{k, 1} = order - masks(k, :);
        specs{k, 2} = [masks(k, :); masks(k, :)];
    end
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

function degree = expandDegree(value, nPar)
    %EXPANDDEGREE Normalize scalar shorthand for the independent oracle.
    degree = reshape(value, 1, []);
    if isscalar(degree)
        degree = repmat(degree, 1, nPar);
    end
end

function veriConCel(testCase, actual, reference)
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

function map = mapRecord(gramDegree, alphaPower, oneMinusAlphaPower, basisLabels)
    map = struct( ...
        GramDegree=gramDegree, ...
        AlphaPower=alphaPower, ...
        OneMinusAlphaPower=oneMinusAlphaPower, ...
        BasisLabels=basisLabels);
end

function rows = labelRows(maxLabel)
    rows = tests.infrastructure.labels(maxLabel);
end

function restorePath(originalPath)
    path(originalPath);
    clear export
end
function test_all_cells_rates_entries_and_signs(testCase)
    state=warning('off','pdlmi:ElementwiseInequality');
    cleanup=onCleanup(@() warning(state)); %#ok<NASGU>
    for entrywise=[false true]
        if entrywise, P=pdvar(2,1,[0 2 5],'full',Degree=3,RateBounds=[-2 3]);
        else, P=pdvar(2,[0 2 5],Degree=3,RateBounds=[-2 3]); end
        R=rhodiff(P);
        for relation=[">=" "<="]
            direct=pdlmi(R,relation);
            [target,specs]=fullBoxSpecs(1,R.Degree,2);
            veriLegCer(testCase,direct.useFullBox(2),target,specs,[],entrywise);
            veriLegCer(testCase,direct.usePutinar(2),target,specs,[],entrywise);
            veriLegCer(testCase,direct.useSpBox(2,2),target,specs,2,entrywise);
            veriLegCer(testCase,direct.useSpPut(2,2),target,specs,2,entrywise);
        end
    end
end


function test_odd_interval_identity_all_cells(testCase)
    R=pdvar(2,[0 2 5],Degree=3);
    [target,specs]=fullBoxSpecs(1,3,2);
    for relation=[">=" "<="]
        direct=pdlmi(R,relation);
        veriLegCer(testCase,direct.useFullBox(2),target,specs,[]);
        veriLegCer(testCase,direct.usePutinar(2),target,specs,[]);
        veriLegCer(testCase,direct.useSpBox(2,2),target,specs,2);
        veriLegCer(testCase,direct.useSpPut(2,2),target,specs,2);
    end
end

function test_tensor_zero_axis_mixed_rates_complete_gram_identities(testCase)
    % Combine tensor masking, unequal cells, rectangular entries and rate rows.
    state = warning('off', 'pdlmi:ElementwiseInequality');
    cleanup = onCleanup(@() warning(state)); %#ok<NASGU>
    P = pdvar(2, 1, {[0 1 4], [-2 0 3]}, 'full', ...
        Degree=[0 2], RateBounds=[2 2; -1 3]);
    R = [2 -1; 3 4] * rhodiff(P) + [5; -7];
    [target, box] = fullBoxSpecs(2, R.Degree, [0 2]);
    put = putinarSpecs(2, [0 2]);
    for relation = [">=" "<="]
        direct = pdlmi(R, relation);
        veriLegCer(testCase, direct.useFullBox([0 2]), target, box, [], true);
        veriLegCer(testCase, direct.usePutinar([0 2]), target, put, [], true);
        veriLegCer(testCase, direct.useSpBox(2, [0 2]), target, box, 2, true);
        veriLegCer(testCase, direct.useSpPut(2, [0 2]), target, put, 2, true);
    end
end
