function plan = productPlan(obj, lhsDeg, rhsDeg)
    %PRODUCTPLAN Precompute one tensor Bernstein product map.

    nPar = obj.npar();
    lhsDeg = chkDegree(lhsDeg, "lhsDeg");
    rhsDeg = chkDegree(rhsDeg, "rhsDeg");
    outDeg = lhsDeg + rhsDeg;

    lhsLabels = helper.combRows(repmat({0:lhsDeg}, 1, nPar));
    rhsLabels = helper.combRows(repmat({0:rhsDeg}, 1, nPar));
    outLabels = helper.combRows(repmat({0:outDeg}, 1, nPar));
    lhsWeights = tensorWeights(lhsLabels, lhsDeg);
    rhsWeights = tensorWeights(rhsLabels, rhsDeg);
    outWeights = tensorWeights(outLabels, outDeg);
    rhsMult = (rhsDeg + 1) .^ (nPar - 1:-1:0);

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

function degree = chkDegree(value, name)
    %CHKDEGREE Validate one product-plan degree.
    degree = double(helper.chk(value, "pdbase:InvalidDegree", ...
        name + " must be a nonnegative integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
end

function weights = tensorWeights(labels, degree)
    %TENSORWEIGHTS Return products of one-dimensional binomial weights.
    choose = arrayfun(@(k) nchoosek(degree, k), 0:degree);
    selected = reshape(choose(labels + 1), size(labels));
    weights = prod(selected, 2);
end

function indices = tensorIndices(labels, degree)
    %TENSORINDICES Map repository label order into MATLAB tensor storage.
    % combRows makes earlier parameter axes vary slowly, while MATLAB linear
    % indexing makes the first tensor axis vary fastest; this permutation
    % places each label on its parameter axis before convn is applied.
    multipliers = (degree + 1) .^ (0:size(labels, 2) - 1);
    indices = labels * multipliers' + 1;
end

function shape = tensorShape(degree, nPar)
    %TENSORSHAPE Keep one-parameter coefficient tensors as column vectors.
    shape = repmat(degree + 1, 1, nPar);
    if nPar == 1
        shape = [degree + 1, 1];
    end
end
