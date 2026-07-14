function vals = fitVals(info, deg, sz, evalFcn)
    %FITVALS Fit local Bernstein coefficients from affine point samples.
    %
    %   Syntax:
    %     vals = fitVals(gridInfo, degree, matrixSize, evalFcn)
    %
    %   Example (internal interpolation path):
    %     info = helper.mkGrid({[0 1]}, "pdvar");
    %     vals = fitVals(info, 1, [1 1], @(pt) pt(1));
    %
    %   The evaluator is sampled at the tensor-product Bernstein interpolation
    %   points in every physical cell. The returned nested tree uses the
    %   package's flat combination order and retains affine sdpvar payloads.

    vecs = info.Vectors;
    nPar = numel(vecs);
    lbls = helper.combRows(repmat({0:deg}, 1, nPar));
    nCoeff = size(lbls, 1);
    alphas = zeros(nCoeff, nPar);
    if deg > 0
        alphas = lbls ./ deg;
    end

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

    % W maps point samples back to local Bernstein coefficients; keeping
    % samples in cells lets numeric and affine sdpvar payloads share the path.
    W = V \ eye(nCoeff);
    nCell = info.NumNodes - 1;
    vals = helper.mkNest(nCell, @(subs) coeffsAt( ...
        subs, vecs, alphas, W, nCoeff, sz, evalFcn));
end

function coeffs = coeffsAt(cellSubs, vecs, alphas, W, nCoeff, sz, evalFcn)
    %COEFFSAT Sample and solve one cell's Bernstein interpolation problem.
    %
    %   Syntax:
    %     coeffs = coeffsAt(cellSubs, vecs, alphas, W, nCoeff, sz, evalFcn)
    %
    %   W maps ordered point samples to ordered local coefficients; the cell
    %   bounds convert forward alpha=(rho-lo)/(hi-lo) back to physical points.
    nPar = numel(vecs);
    bounds = zeros(nPar, 2);
    for p = 1:nPar
        v = vecs{p};
        bounds(p, :) = v(cellSubs(p):(cellSubs(p) + 1));
    end

    samples = cell(1, nCoeff);
    for s = 1:nCoeff
        % Map the forward local coordinate back into this physical cell.
        pt = bounds(:, 1).' + alphas(s, :) .* (bounds(:, 2).' - bounds(:, 1).');
        samples{s} = evalFcn(pt);
    end

    coeffs = cell(1, nCoeff);
    for c = 1:nCoeff
        acc = zeros(sz);
        for s = 1:nCoeff
            acc = acc + samples{s} .* W(c, s);
        end
        coeffs{c} = acc;
    end
end
