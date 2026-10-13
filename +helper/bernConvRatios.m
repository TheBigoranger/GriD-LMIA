function ratios = bernConvRatios(lhsLabels, lhsDegree, ...
        rhsLabels, rhsDegree, outputLabels, outputDegree)
    %BERNCONVRATIOS Return stable row-aligned Bernstein convolution ratios.
    %
    %   Syntax:
    %     ratios = helper.bernConvRatios(lhsLabels, lhsDegree, ...
    %         rhsLabels, rhsDegree)
    %     ratios = helper.bernConvRatios(lhsLabels, lhsDegree, ...
    %         rhsLabels, rhsDegree, outputLabels, outputDegree)
    %
    %   The four-argument form infers summed output labels and degrees. The
    %   six-argument form supports shifted Gram outputs such as multiplication
    %   by alpha^a*(1-alpha)^b.
    if nargin == 4
        chkPairShape(lhsLabels, lhsDegree, rhsLabels, rhsDegree);
        outputLabels = lhsLabels + rhsLabels;
        outputDegree = lhsDegree + rhsDegree;
    elseif nargin ~= 6
        error("helper:InvalidBernConvRatios", ...
            "Bernstein convolution ratios require four or six inputs.");
    end
    chkInputs(lhsLabels, lhsDegree, rhsLabels, rhsDegree, ...
        outputLabels, outputDegree);

    lhsWeights = helper.bernConvWeights(lhsLabels, lhsDegree);
    rhsWeights = helper.bernConvWeights(rhsLabels, rhsDegree);
    outputWeights = helper.bernConvWeights(outputLabels, outputDegree);

    % Normalized binomial weights differ from raw coefficients by powers of
    % two. pow2 applies the exact degree correction without another large
    % intermediate binomial coefficient.
    degreeShift = sum(lhsDegree + rhsDegree - outputDegree);
    numerator = lhsWeights .* rhsWeights;
    ratios = pow2(numerator ./ outputWeights, degreeShift);
    % A normalized mass can underflow even when its binomial ratio is finite.
    % Recompute only those rows in log space, after cancelling powers of two.
    small = numerator < realmin | outputWeights < realmin | ~isfinite(ratios);
    if any(small)
        logs = zeros(nnz(small), 1);
        for dim = 1:numel(lhsDegree)
            logs = logs + logBinom(lhsDegree(dim), lhsLabels(small, dim)) ...
                + logBinom(rhsDegree(dim), rhsLabels(small, dim)) ...
                - logBinom(outputDegree(dim), outputLabels(small, dim));
        end
        ratios(small) = exp(logs);
    end
end

function out = logBinom(degree, labels)
    out = gammaln(degree + 1) - gammaln(labels + 1) ...
        - gammaln(degree - labels + 1);
end

function chkPairShape(lhsLabels, lhsDegree, rhsLabels, rhsDegree)
    %CHKPAIRSHAPE Reject inputs that cannot form inferred output labels.
    valid = isnumeric(lhsLabels) && isnumeric(rhsLabels) && ...
        ismatrix(lhsLabels) && ismatrix(rhsLabels) && ...
        isequal(size(lhsLabels), size(rhsLabels)) && ...
        isnumeric(lhsDegree) && isnumeric(rhsDegree) && ...
        isrow(lhsDegree) && isrow(rhsDegree) && ...
        isequal(size(lhsDegree), size(rhsDegree));
    if ~valid
        error("helper:InvalidBernConvRatios", ...
            "Labels and degrees must be valid row-aligned Bernstein tables.");
    end
end

function chkInputs(lhsLabels, lhsDegree, rhsLabels, rhsDegree, ...
        outputLabels, outputDegree)
    %CHKINPUTS Require aligned label rows and normalized degree vectors.
    degrees = {lhsDegree, rhsDegree, outputDegree};
    labels = {lhsLabels, rhsLabels, outputLabels};
    nPar = numel(lhsDegree);
    nRows = size(lhsLabels, 1);
    valid = nPar > 0;
    for k = 1:numel(degrees)
        degree = degrees{k};
        table = labels{k};
        valid = valid && isnumeric(degree) && isreal(degree) && ...
            isrow(degree) && numel(degree) == nPar && ...
            all(isfinite(degree)) && all(degree >= 0) && ...
            all(mod(degree, 1) == 0) && ...
            isnumeric(table) && isreal(table) && ismatrix(table) && ...
            ~isempty(table) && size(table, 1) == nRows && ...
            size(table, 2) == nPar && all(isfinite(table), "all") && ...
            all(table >= 0, "all") && all(mod(table, 1) == 0, "all");
        if valid
            valid = all(table <= degree, "all");
        end
    end
    if ~valid
        error("helper:InvalidBernConvRatios", ...
            "Labels and degrees must be valid row-aligned Bernstein tables.");
    end
end
