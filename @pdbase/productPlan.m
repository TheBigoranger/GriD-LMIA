function plan = productPlan(obj, lhsDeg, rhsDeg)
    %PRODUCTPLAN Precompute one tensor Bernstein product map.

    nPar = obj.npar();
    lhsDeg = helper.normalizeDegree(lhsDeg, nPar, ...
        "pdbase:InvalidDegree", "lhsDeg");
    rhsDeg = helper.normalizeDegree(rhsDeg, nPar, ...
        "pdbase:InvalidDegree", "rhsDeg");
    outDeg = lhsDeg + rhsDeg;

    lhsLabels = helper.combRows(arrayfun(@(deg) 0:deg, lhsDeg, ...
        "UniformOutput", false));
    rhsLabels = helper.combRows(arrayfun(@(deg) 0:deg, rhsDeg, ...
        "UniformOutput", false));
    outLabels = helper.combRows(arrayfun(@(deg) 0:deg, outDeg, ...
        "UniformOutput", false));
    lhsWeights = tensorWeights(lhsLabels, lhsDeg);
    rhsWeights = tensorWeights(rhsLabels, rhsDeg);
    outWeights = tensorWeights(outLabels, outDeg);
    rhsMult = rowMajorMultipliers(rhsDeg);

    pairs = cell(size(outLabels, 1), 1);
    scales = cell(size(outLabels, 1), 1);
    for outIdx = 1:size(outLabels, 1)
        rhsCandidate = outLabels(outIdx, :) - lhsLabels;
        keep = all(rhsCandidate >= 0, 2) & ...
            all(rhsCandidate <= rhsDeg, 2);
        lhsIdx = find(keep);
        rhsIdx = rhsCandidate(keep, :) * rhsMult' + 1;
        pairs{outIdx} = [lhsIdx, rhsIdx];
        scales{outIdx} = lhsWeights(lhsIdx) .* ...
            rhsWeights(rhsIdx) ./ outWeights(outIdx);
    end

    plan.NumParameters = nPar;
    plan.LhsDegree = lhsDeg;
    plan.RhsDegree = rhsDeg;
    plan.OutputDegree = outDeg;
    plan.LhsCount = size(lhsLabels, 1);
    plan.RhsCount = size(rhsLabels, 1);
    plan.OutputCount = size(outLabels, 1);
    plan.Pairs = pairs;
    plan.Scales = scales;
    plan.LhsWeights = lhsWeights;
    plan.RhsWeights = rhsWeights;
    plan.OutputWeights = outWeights;
    plan.LhsTensorIndices = tensorIndices(lhsLabels, lhsDeg);
    plan.RhsTensorIndices = tensorIndices(rhsLabels, rhsDeg);
    plan.OutputTensorIndices = tensorIndices(outLabels, outDeg);
    plan.LhsShape = tensorShape(lhsDeg, nPar);
    plan.RhsShape = tensorShape(rhsDeg, nPar);
    plan.OutputShape = tensorShape(outDeg, nPar);
end

function weights = tensorWeights(labels, degree)
    %TENSORWEIGHTS Return products of one-dimensional binomial weights.
    selected = ones(size(labels));
    for dim = 1:numel(degree)
        selected(:, dim) = arrayfun( ...
            @(k) nchoosek(degree(dim), k), labels(:, dim));
    end
    weights = prod(selected, 2);
end

function indices = tensorIndices(labels, degree)
    %TENSORINDICES Map repository label order into MATLAB tensor storage.
    % combRows makes earlier parameter axes vary slowly, while MATLAB linear
    % indexing makes the first tensor axis vary fastest; this permutation
    % places each label on its parameter axis before convn is applied.
    multipliers = cumprod([1, degree(1:end - 1) + 1]);
    indices = labels * multipliers' + 1;
end

function shape = tensorShape(degree, nPar)
    %TENSORSHAPE Keep one-parameter coefficient tensors as column vectors.
    shape = degree + 1;
    if nPar == 1
        shape = [degree + 1, 1];
    end
end

function multipliers = rowMajorMultipliers(degree)
    %ROWMAJORMULTIPLIERS Map combRows labels to flat repository positions.
    multipliers = fliplr(cumprod([1, fliplr(degree(2:end) + 1)]));
end
