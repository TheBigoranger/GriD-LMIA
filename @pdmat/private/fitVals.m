function [vals, lbls] = fitVals(info, deg, sz, evalFcn)
    %FITVALS Fit local Bernstein coefficients from point samples.
    %
    %   Syntax:
    %     vals = fitVals(gridInfo, degree, matrixSize, evalFcn)
    %     [vals, lbls] = fitVals(gridInfo, degree, matrixSize, evalFcn)
    %
    %   Example:
    %     info = helper.mkGrid({[0 1]}, "pdmat");
    %     vals = fitVals(info, 1, [1 1], @(pt) pt(1));

    vecs = info.Vectors;
    nPar = numel(vecs);
    lbls = helper.combRows(repmat({0:deg}, 1, nPar));
    nCoeff = size(lbls, 1);
    alphas = zeros(nCoeff, nPar);
    if deg > 0
        alphas = lbls ./ deg;
    end

    % Use forward alpha=(rho-lo)/(hi-lo), so labels count alpha powers.
    % Vandermonde rows evaluate Bernstein coefficients at interpolation points.
    V = zeros(nCoeff, nCoeff);
    for s = 1:nCoeff
        for k = 1:nCoeff
            w = 1;
            for p = 1:nPar
                j = lbls(k, p);
                a = alphas(s, p);
                w = w * nchoosek(deg, j) * (1 - a)^(deg - j) * a^j;
            end
            V(s, k) = w;
        end
    end

    nCell = info.NumNodes - 1;
    vals = helper.mkNest(nCell, @(subs) coeffsAt( ...
        subs, vecs, alphas, V, nCoeff, sz, evalFcn));
end

function coeffs = coeffsAt(cellSubs, vecs, alphas, V, nCoeff, sz, evalFcn)
    nPar = numel(vecs);
    bounds = zeros(nPar, 2);
    for p = 1:nPar
        v = vecs{p};
        bounds(p, :) = v(cellSubs(p):(cellSubs(p) + 1));
    end

    samples = zeros(nCoeff, prod(sz));
    for s = 1:nCoeff
        % Map the forward local coordinate back into this physical cell.
        pt = bounds(:, 1).' + alphas(s, :) .* (bounds(:, 2).' - bounds(:, 1).');
        val = evalFcn(pt);
        samples(s, :) = val(:).';
    end

    rows = V \ samples;
    coeffs = cell(1, nCoeff);
    for c = 1:nCoeff
        coeffs{c} = reshape(rows(c, :), sz);
    end
end
