function [vals, labels] = fitVals(info, deg, sz, evalFcn, owner)
    %FITVALS Fit cell-local Bernstein coefficients from point samples.
    %
    %   Syntax:
    %     vals = helper.fitVals(info, deg, sz, evalFcn, owner)
    %     [vals, labels] = helper.fitVals(info, deg, sz, evalFcn, owner)
    %
    %   Arguments:
    %     info    - Normalized grid metadata with Vectors and NumNodes fields.
    %     deg     - Scalar or 1-by-ell Bernstein degree.
    %     sz      - Matrix payload size for every sampled value.
    %     evalFcn - Function handle accepting one row parameter point.
    %     owner   - Error identifier stem for degree validation.
    %
    %   Output:
    %     vals   - Nested cell-local coefficient tree in combRows label order.
    %     labels - Local Bernstein labels used for every physical cell.
    %
    %   Example:
    %     grid = helper.mkGrid({[0 1]});
    %     vals = helper.fitVals(grid, 1, [1 1], @(rho) rho(1), "pdmat");
    %
    %   The fitting points are the local tensor Bernstein nodes. The same
    %   inverse basis matrix is reused for every physical cell, while evalFcn
    %   sees points mapped to that cell's physical parameter bounds.
    vecs = info.Vectors;
    nPar = numel(vecs);
    deg = helper.normDeg(deg, nPar, owner + ":InvalidDegree", "Degree");
    labels = helper.combRows(arrayfun(@(d) 0:d, deg, ...
        "UniformOutput", false));
    nCoeff = size(labels, 1);
    alphas = zeros(nCoeff, nPar);
    active = deg > 0;
    alphas(:, active) = labels(:, active) ./ deg(active);
    basis = zeros(nCoeff, nCoeff);
    for s = 1:nCoeff
        for k = 1:nCoeff
            term = 1;
            for p = 1:nPar
                q = labels(k, p);
                term = term * nchoosek(deg(p), q) * ...
                    alphas(s, p) ^ q * ...
                    (1 - alphas(s, p)) ^ (deg(p) - q);
            end
            basis(s, k) = term;
        end
    end
    weights = basis \ eye(nCoeff);
    nCell = info.NumNodes - 1;
    vals = helper.mkNest(nCell, @fitCell);

    function coeffs = fitCell(subs)
        bounds = zeros(nPar, 2);
        for p = 1:nPar
            bounds(p, :) = vecs{p}(subs(p):(subs(p) + 1));
        end
        samples = cell(1, nCoeff);
        for s = 1:nCoeff
            pt = bounds(:, 1).' + alphas(s, :) .* ...
                (bounds(:, 2).' - bounds(:, 1).');
            samples{s} = evalFcn(pt);
        end
        coeffs = cell(1, nCoeff);
        for c = 1:nCoeff
            acc = zeros(sz);
            for s = 1:nCoeff
                acc = acc + samples{s} .* weights(c, s);
            end
            coeffs{c} = acc;
        end
    end
end
