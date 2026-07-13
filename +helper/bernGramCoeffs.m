function coeffs = bernGramCoeffs(gram, gramDegree, alphaPower, oneMinusAlphaPower)
    %BERNGRAMCOEFFS Map a weighted tensor Bernstein Gram form to coefficients.
    %
    %   coeffs = helper.bernGramCoeffs(Q,d,a,b) returns coefficients of
    %   alpha.^a.*(1-alpha).^b.*Z_d'*Q*Z_d in repository combRows order.
    %   d, a, and b contain one nonnegative integer per parameter direction.
    %   Q uses basis-major blocks, with one matrix block per tensor label.
    %   The result has tensor degree 2*d+a+b and contains matrix coefficients.
    %
    %   Invalid degrees or weight powers raise helper:InvalidGramPowers. A Q
    %   that is not square, or whose dimension is not a multiple of the tensor
    %   basis size, raises helper:InvalidGramShape.

    gramDegree = rowVector(gramDegree, "gramDegree");
    nPar = numel(gramDegree);
    alphaPower = rowVector(alphaPower, "alphaPower");
    oneMinusAlphaPower = rowVector(oneMinusAlphaPower, "oneMinusAlphaPower");
    allPowers = [gramDegree, alphaPower, oneMinusAlphaPower];
    if numel(alphaPower) ~= nPar || numel(oneMinusAlphaPower) ~= nPar || ...
            any(allPowers < 0) || any(mod(allPowers, 1) ~= 0)
        error("helper:InvalidGramPowers", ...
            "Gram degrees and weight powers must be nonnegative integer vectors of equal length.");
    end
    nBasis = prod(gramDegree + 1);
    if size(gram, 1) ~= size(gram, 2) || mod(size(gram, 1), nBasis) ~= 0
        error("helper:InvalidGramShape", ...
            "Gram matrix size must be a square multiple of the tensor basis size.");
    end
    n = size(gram, 1) / nBasis;
    targetDegree = 2 * gramDegree + alphaPower + oneMinusAlphaPower;
    basisLabels = helper.combRows(arrayfun(@(d) 0:d, gramDegree, ...
        "UniformOutput", false));
    targetLabels = helper.combRows(arrayfun(@(d) 0:d, targetDegree, ...
        "UniformOutput", false));
    coeffs = repmat({zeros(n)}, 1, size(targetLabels, 1));

    % Multiplying B_i,d B_j,d alpha^a (1-alpha)^b shifts the output label by
    % b, because repository Bernstein labels count powers of (1-alpha).
    % Normalization then contributes one binomial ratio per direction.
    for i = 1:nBasis
        iBlock = (i - 1) * n + (1:n);
        for j = 1:nBasis
            jBlock = (j - 1) * n + (1:n);
            label = basisLabels(i, :) + basisLabels(j, :) + ...
                oneMinusAlphaPower;
            [~, out] = ismember(label, targetLabels, "rows");
            scale = 1;
            for dim = 1:nPar
                scale = scale * nchoosek(gramDegree(dim), basisLabels(i, dim)) * ...
                    nchoosek(gramDegree(dim), basisLabels(j, dim)) / ...
                    nchoosek(targetDegree(dim), label(dim));
            end
            coeffs{out} = coeffs{out} + scale * gram(iBlock, jBlock);
        end
    end
end

function out = rowVector(val, name)
    if ~isnumeric(val) || ~isreal(val) || isempty(val) || ~isvector(val) || ...
            any(~isfinite(val))
        error("helper:InvalidGramPowers", "%s must be a finite real vector.", name);
    end
    out = reshape(double(val), 1, []);
end
