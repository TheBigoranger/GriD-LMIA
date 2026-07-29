function plan = elevationPlan(fromDeg, toDeg, nPar)
    %ELEVATIONPLAN Precompute one sparse tensor degree-elevation operator.

    nPar = double(helper.chk(nPar, "pdbase:InvalidParameterDimension", ...
        "nPar must be a positive integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "positive"));
    fromDeg = helper.normalizeDegree(fromDeg, nPar, ...
        "pdbase:InvalidDegree", "fromDeg");
    toDeg = helper.normalizeDegree(toDeg, nPar, ...
        "pdbase:InvalidDegree", "toDeg");
    if any(toDeg < fromDeg)
        error("pdbase:InvalidDegreeElevation", ...
            "Cannot degree-elevate to a lower degree in any parameter direction.");
    end

    sourceLabels = helper.combRows(arrayfun(@(deg) 0:deg, fromDeg, ...
        "UniformOutput", false));
    targetLabels = helper.combRows(arrayfun(@(deg) 0:deg, toDeg, ...
        "UniformOutput", false));
    sourceWeights = tensorWeights(sourceLabels, fromDeg);
    targetWeights = tensorWeights(targetLabels, toDeg);
    gap = toDeg - fromDeg;

    rows = [];
    cols = [];
    values = [];
    for targetIdx = 1:size(targetLabels, 1)
        delta = targetLabels(targetIdx, :) - sourceLabels;
        keep = all(delta >= 0, 2) & all(delta <= gap, 2);
        sourceIdx = find(keep);
        selected = ones(numel(sourceIdx), nPar);
        keptDelta = delta(keep, :);
        for dim = 1:nPar
            selected(:, dim) = arrayfun( ...
                @(k) nchoosek(gap(dim), k), keptDelta(:, dim));
        end
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

function weights = tensorWeights(labels, degree)
    %TENSORWEIGHTS Return products of one-dimensional binomial weights.
    selected = ones(size(labels));
    for dim = 1:numel(degree)
        selected(:, dim) = arrayfun( ...
            @(k) nchoosek(degree(dim), k), labels(:, dim));
    end
    weights = prod(selected, 2);
end
