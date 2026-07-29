function vals = fitVals(info, deg, sz, evalFcn)
    %FITVALS Fit local Bernstein coefficients from affine point samples.
    %
    %   Syntax:
    %     vals = fitVals(gridInfo, degree, matrixSize, evalFcn)
    %
    %   Arguments:
    %     gridInfo   - Normalized tensor-grid metadata.
    %     degree     - Scalar or per-parameter Bernstein degree.
    %     matrixSize - Matrix size returned by evalFcn.
    %     evalFcn    - Affine evaluator accepting one physical-point row.
    %
    %   Output:
    %     vals - Nested cell-local coefficient tree.
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
    deg = helper.normalizeDegree(deg, nPar, ...
        "pdvar:InvalidDegree", "Degree");
    lbls = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, deg, ...
        "UniformOutput", false));
    nCoeff = size(lbls, 1);
    alphas = zeros(nCoeff, nPar);
    positive = deg > 0;
    if any(positive)
        alphas(:, positive) = lbls(:, positive) ./ deg(positive);
    end

    V = zeros(nCoeff, nCoeff);
    for s = 1:nCoeff
        for k = 1:nCoeff
            w = 1;
            for p = 1:nPar
                j = lbls(k, p);
                a = alphas(s, p);
                oneDeg = deg(p);
                w = w * nchoosek(oneDeg, j) * ...
                    (1 - a)^(oneDeg - j) * a^j;
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
