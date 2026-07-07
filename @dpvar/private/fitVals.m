function vals = fitVals(info, deg, sz, evalFcn)
    %FITVALS Fit local Bernstein coefficients from affine point samples.

    vecs = info.Vectors;
    nPar = numel(vecs);
    lbls = internal.combRows(repmat({0:deg}, 1, nPar));
    nCoeff = size(lbls, 1);
    alphas = ones(nCoeff, nPar);
    if deg > 0
        alphas = 1 - lbls ./ deg;
    end

    V = zeros(nCoeff, nCoeff);
    for s = 1:nCoeff
        for k = 1:nCoeff
            w = 1;
            for p = 1:nPar
                j = lbls(k, p);
                a = alphas(s, p);
                w = w * nchoosek(deg, j) * a^(deg - j) * (1 - a)^j;
            end
            V(s, k) = w;
        end
    end

    % W maps point samples back to local Bernstein coefficients; keeping
    % samples in cells lets numeric and affine sdpvar payloads share the path.
    W = V \ eye(nCoeff);
    nCell = info.NumNodes - 1;
    vals = internal.mkNest(nCell, @(subs) coeffsAt( ...
        subs, vecs, alphas, W, nCoeff, sz, evalFcn));
end

function coeffs = coeffsAt(cellSubs, vecs, alphas, W, nCoeff, sz, evalFcn)
    nPar = numel(vecs);
    bounds = zeros(nPar, 2);
    for p = 1:nPar
        v = vecs{p};
        bounds(p, :) = v(cellSubs(p):(cellSubs(p) + 1));
    end

    samples = cell(1, nCoeff);
    for s = 1:nCoeff
        % alpha=1 is the lower face and alpha=0 is the upper face.
        pt = bounds(:, 1).' + (1 - alphas(s, :)) .* (bounds(:, 2).' - bounds(:, 1).');
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
