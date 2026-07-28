function plan = elevationPlan(fromDeg, toDeg, nPar)
    %ELEVATIONPLAN Precompute one sparse tensor degree-elevation operator.

    fromDeg = chkDegree(fromDeg, "fromDeg");
    toDeg = chkDegree(toDeg, "toDeg");
    nPar = double(helper.chk(nPar, "pdbase:InvalidParameterDimension", ...
        "nPar must be a positive integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "positive"));
    if toDeg < fromDeg
        error("pdbase:InvalidDegreeElevation", ...
            "Cannot degree-elevate from degree %d to lower degree %d.", ...
            fromDeg, toDeg);
    end

    sourceLabels = helper.combRows(repmat({0:fromDeg}, 1, nPar));
    targetLabels = helper.combRows(repmat({0:toDeg}, 1, nPar));
    sourceWeights = tensorWeights(sourceLabels, fromDeg);
    targetWeights = tensorWeights(targetLabels, toDeg);
    gap = toDeg - fromDeg;
    gapChoose = arrayfun(@(k) nchoosek(gap, k), 0:gap);

    rows = [];
    cols = [];
    values = [];
    for targetIdx = 1:size(targetLabels, 1)
        delta = targetLabels(targetIdx, :) - sourceLabels;
        keep = all(delta >= 0, 2) & all(delta <= gap, 2);
        sourceIdx = find(keep);
        selected = reshape(gapChoose(delta(keep, :) + 1), ...
            size(delta(keep, :)));
        scales = sourceWeights(sourceIdx) .* prod(selected, 2) ./ ...
            targetWeights(targetIdx);
        rows = [rows; repmat(targetIdx, numel(sourceIdx), 1)]; %#ok<AGROW>
        cols = [cols; sourceIdx]; %#ok<AGROW>
        values = [values; scales]; %#ok<AGROW>
    end

    plan.FromDegree = fromDeg;
    plan.ToDegree = toDeg;
    plan.NumParameters = nPar;
    plan.SourceCount = size(sourceLabels, 1);
    plan.TargetCount = size(targetLabels, 1);
    % Rows are target coefficients and columns are source coefficients; bernElev
    % therefore applies the transpose to horizontally packed coefficient blocks.
    plan.Operator = sparse(rows, cols, values, ...
        plan.TargetCount, plan.SourceCount);
end

function degree = chkDegree(value, name)
    %CHKDEGREE Validate one elevation-plan degree.
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
