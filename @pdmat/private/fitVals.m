function [vals, lbls] = fitVals(info, deg, sz, evalFcn)
    %FITVALS Fit local Bernstein coefficients from point samples.
    %
    %   Syntax:
    %     vals = fitVals(gridInfo, degree, matrixSize, evalFcn)
    %     [vals, lbls] = fitVals(gridInfo, degree, matrixSize, evalFcn)
    %
    %   Arguments:
    %     gridInfo   - Normalized tensor-grid metadata.
    %     degree     - Scalar or per-parameter Bernstein degree.
    %     matrixSize - Matrix size returned by evalFcn.
    %     evalFcn    - Evaluator accepting one physical-point row.
    %
    %   Output:
    %     vals - Nested fitted coefficient tree.
    %     lbls - Flat local labels matching each leaf column.
    %
    %   Example:
    %     info = helper.mkGrid({[0 1]}, "pdmat");
    %     vals = fitVals(info, 1, [1 1], @(pt) pt(1));

    vecs = info.Vectors;
    nPar = numel(vecs);
    deg = helper.normalizeDegree(deg, nPar, ...
        "pdmat:InvalidDegree", "Degree");
    lbls = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, deg, ...
        "UniformOutput", false));
    nCoeff = size(lbls, 1);
    alphas = zeros(nCoeff, nPar);
    positive = deg > 0;
    if any(positive)
        alphas(:, positive) = lbls(:, positive) ./ deg(positive);
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
                oneDeg = deg(p);
                w = w * nchoosek(oneDeg, j) * ...
                    (1 - a)^(oneDeg - j) * a^j;
            end
            V(s, k) = w;
        end
    end

    nCell = info.NumNodes - 1;
    vals = helper.mkNest(nCell, @(subs) coeffsAt( ...
        subs, vecs, alphas, V, nCoeff, sz, evalFcn));
end

function coeffs = coeffsAt(cellSubs, vecs, alphas, V, nCoeff, sz, evalFcn)
    %COEFFSAT Fit one physical cell from ordered interpolation samples.
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
