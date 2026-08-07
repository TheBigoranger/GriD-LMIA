function weights = bernConvWeights(labels, degree)
    %BERNCONVWEIGHTS Return normalized tensor Bernstein binomial weights.
    %
    %   Syntax:
    %     weights = helper.bernConvWeights(labels, degree)
    %
    %   Arguments:
    %     labels - Local Bernstein multi-index labels, one label per row.
    %     degree - Normalized 1-by-ell nonnegative integer degree vector.
    %
    %   Output:
    %     weights - Column vector containing
    %               prod_s nchoosek(degree(s), labels(:,s)) / 2^sum(degree).
    %
    %   Example:
    %     labels = helper.combRows({0:2, 0:1});
    %     weights = helper.bernConvWeights(labels, [2 1]);
    %
    %   Each one-dimensional table is generated outward from its mode. This
    %   avoids forming the overflowing raw binomial coefficient before the
    %   convolution normalization is applied.
    chkInputs(labels, degree);

    weights = ones(size(labels, 1), 1);
    for dim = 1:numel(degree)
        axisWeights = modeWeights(degree(dim));
        weights = weights .* axisWeights(labels(:, dim) + 1);
    end
end

function weights = modeWeights(degree)
    %MODEWEIGHTS Build the symmetric Binomial(degree, 1/2) mass table.
    weights = zeros(degree + 1, 1);
    leftMode = floor(degree / 2);
    rightMode = ceil(degree / 2);
    weights(leftMode + 1) = 1;
    weights(rightMode + 1) = 1;

    % Mirror the downward recurrence so symmetry is exact in floating point.
    for label = leftMode:-1:1
        next = weights(label + 1) * label / (degree - label + 1);
        weights(label) = next;
        weights(degree - label + 2) = next;
    end
    weights = weights ./ sum(weights);
end

function chkInputs(labels, degree)
    %CHKINPUTS Enforce the normalized internal label-table contract.
    validDegree = isnumeric(degree) && isreal(degree) && isrow(degree) && ...
        ~isempty(degree) && all(isfinite(degree)) && ...
        all(degree >= 0) && all(mod(degree, 1) == 0);
    validLabels = isnumeric(labels) && isreal(labels) && ismatrix(labels) && ...
        ~isempty(labels) && size(labels, 2) == numel(degree) && ...
        all(isfinite(labels), "all") && all(labels >= 0, "all") && ...
        all(mod(labels, 1) == 0, "all");
    if validDegree && validLabels
        validLabels = all(labels <= degree, "all");
    end
    if ~validDegree || ~validLabels
        error("helper:InvalidBernConvWeights", ...
            "Labels and degree must form a valid normalized Bernstein label table.");
    end
end
