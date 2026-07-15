function coeffs = bernGramCoeffs(gram, gramDegree, alphaPower, oneMinusAlphaPower)
    %BERNGRAMCOEFFS Map a weighted tensor Bernstein Gram form to coefficients.
    %
    %   Syntax:
    %     coeffs = bernGramCoeffs(Q, d, alphaPower, oneMinusAlphaPower)
    %
    %   Arguments:
    %     Q                  - Square basis-major block Gram matrix.
    %     d                  - Tensor Bernstein degree of the Gram basis.
    %     alphaPower         - Per-axis powers of alpha.
    %     oneMinusAlphaPower - Per-axis powers of 1-alpha.
    %
    %   Output:
    %     coeffs - Flat matrix coefficients in helper.combRows order.
    %
    %   The result contains coefficients of alpha.^alphaPower .* ...
    %   (1-alpha).^oneMinusAlphaPower .* Z_d' * Q * Z_d.
    %   d, alphaPower, and oneMinusAlphaPower each contain one nonnegative
    %   integer per parameter direction.
    %   Q uses basis-major blocks, with one matrix block per tensor label.
    %   The tensor degree is 2*d + alphaPower + oneMinusAlphaPower.
    %   Labels count alpha powers: label 0 is lower/left and label d is
    %   upper/right in each parameter direction.
    %
    %   Invalid degrees or weight powers raise pdlmi:InvalidGramPowers. A Q
    %   that is not square, or whose dimension is not a multiple of the tensor
    %   basis size, raises pdlmi:InvalidGramShape.

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
    nBasis = prod(gramDegree + 1);
    if size(gram, 1) ~= size(gram, 2) || mod(size(gram, 1), nBasis) ~= 0
        error("pdlmi:InvalidGramShape", ...
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
    % a, because repository Bernstein labels count powers of alpha.
    % Normalization then contributes one binomial ratio per direction.
    for i = 1:nBasis
        iBlock = (i - 1) * n + (1:n);
        for j = 1:nBasis
            jBlock = (j - 1) * n + (1:n);
            label = basisLabels(i, :) + basisLabels(j, :) + ...
                alphaPower;
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

function out = rowVec(val, name)
    if ~isnumeric(val) || ~isreal(val) || isempty(val) || ~isvector(val) || ...
            any(~isfinite(val))
        error("pdlmi:InvalidGramPowers", "%s must be a finite real vector.", name);
    end
    out = reshape(double(val), 1, []);
end
