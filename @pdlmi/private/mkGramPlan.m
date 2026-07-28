function plan = mkGramPlan(gramDegree, alphaPower, oneMinusAlphaPower, basisLabels)
    %MKGRAMPLAN Precompute one weighted tensor Bernstein-Gram coefficient map.

    gramDegree = rowVec(gramDegree, "gramDegree");
    nPar = numel(gramDegree);
    alphaPower = rowVec(alphaPower, "alphaPower");
    oneMinusAlphaPower = rowVec(oneMinusAlphaPower, "oneMinusAlphaPower");
    allPowers = [gramDegree, alphaPower, oneMinusAlphaPower];
    if numel(alphaPower) ~= nPar || numel(oneMinusAlphaPower) ~= nPar || ...
            any(allPowers < 0) || any(mod(allPowers, 1) ~= 0)
        error("pdlmi:InvalidGramPowers", ...
            "Gram degrees and weight powers must be nonnegative integer vectors of equal length.");
    end

    if nargin < 4 || isempty(basisLabels)
        basisLabels = labelRows(gramDegree);
    else
        basisLabels = chkBasisLabels(basisLabels, gramDegree);
    end

    targetDegree = 2 * gramDegree + alphaPower + oneMinusAlphaPower;
    targetCount = prod(targetDegree + 1);
    outputMultipliers = ones(1, nPar);
    for radixIndex = 1:nPar - 1
        outputMultipliers(radixIndex) = ...
            prod(targetDegree(radixIndex + 1:end) + 1);
    end
    gramWeights = tensorWeights(basisLabels, gramDegree);
    targetChoose = arrayfun(@(degree) ...
        arrayfun(@(label) nchoosek(degree, label), 0:degree), ...
        targetDegree, "UniformOutput", false);

    diagonal = cell(targetCount, 1);
    offDiagonal = cell(targetCount, 1);
    nBasis = size(basisLabels, 1);
    % The Gram variable is symmetric, so store each i<j basis pair once.
    % Realization restores both ordered terms Qij and Qji, preserving the
    % matrix-valued coefficient produced by the former full double loop.
    for i = 1:nBasis
        [out, scale] = contribution(i, i);
        diagonal{out}(end + 1, :) = [i, scale];
        for j = i + 1:nBasis
            [out, scale] = contribution(i, j);
            offDiagonal{out}(end + 1, :) = [i, j, scale];
        end
    end

    plan.GramDegree = gramDegree;
    plan.AlphaPower = alphaPower;
    plan.OneMinusAlphaPower = oneMinusAlphaPower;
    plan.BasisLabels = basisLabels;
    plan.BasisCount = nBasis;
    plan.TargetDegree = targetDegree;
    plan.TargetCount = targetCount;
    plan.OutputMultipliers = outputMultipliers;
    plan.Diagonal = diagonal;
    plan.OffDiagonal = offDiagonal;

    function [out, scale] = contribution(i, j)
        % Repository labels use row-major mixed-radix flattening.
        label = basisLabels(i, :) + basisLabels(j, :) + alphaPower;
        out = label * outputMultipliers' + 1;
        denominator = 1;
        for axisIndex = 1:nPar
            denominator = denominator * ...
                targetChoose{axisIndex}(label(axisIndex) + 1);
        end
        scale = gramWeights(i) * gramWeights(j) / denominator;
    end
end

function rows = labelRows(maxLabel)
    %LABELROWS Enumerate one tensor box in repository coefficient order.
    ranges = arrayfun(@(degree) 0:degree, maxLabel, ...
        "UniformOutput", false);
    rows = helper.combRows(ranges);
end

function weights = tensorWeights(labels, degree)
    %TENSORWEIGHTS Return tensor products of Bernstein binomial weights.
    weights = ones(size(labels, 1), 1);
    for parameter = 1:numel(degree)
        choose = arrayfun(@(label) ...
            nchoosek(degree(parameter), label), 0:degree(parameter));
        weights = weights .* reshape( ...
            choose(labels(:, parameter) + 1), [], 1);
    end
end

function labels = chkBasisLabels(labels, gramDegree)
    %CHKBASISLABELS Validate an explicit tensor-basis subset.
    nPar = numel(gramDegree);
    if ~isnumeric(labels) || ~isreal(labels) || isempty(labels) || ...
            size(labels, 2) ~= nPar || any(~isfinite(labels), "all") || ...
            any(mod(labels, 1) ~= 0, "all") || any(labels < 0, "all") || ...
            any(labels > gramDegree, "all") || ...
            size(unique(labels, "rows"), 1) ~= size(labels, 1)
        error("pdlmi:InvalidGramBasis", ...
            "basisLabels must contain unique valid tensor Gram labels.");
    end
    labels = double(labels);
end

function out = rowVec(value, name)
    %ROWVEC Normalize one finite real Gram metadata vector.
    if ~isnumeric(value) || ~isreal(value) || isempty(value) || ...
            ~isvector(value) || any(~isfinite(value))
        error("pdlmi:InvalidGramPowers", ...
            "%s must be a finite real vector.", name);
    end
    out = reshape(double(value), 1, []);
end
