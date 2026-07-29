function out = evaluate(obj, pt)
    %EVALUATE Reconstruct stored Bernstein coefficient rows at one point.
    %
    %   Syntax:
    %     val = evaluate(obj, pt)
    %     val = obj.evaluate(pt)
    %
    %   Arguments:
    %     obj - Coefficient-backed pdbase, pdmat, or pdvar object.
    %     pt  - In-bounds point with one coordinate per parameter.
    %
    %   Output:
    %     val - One reconstructed matrix for an ordinary coefficient row.
    %           Rate-row storage returns a 1-by-N cell array in stored order.
    %
    %   The payload type is preserved: numeric coefficients produce numeric
    %   matrices, while symbolic coefficients produce YALMIP expressions.
    %
    %   Example:
    %     obj = pdbase({[0 2]}, [1 1], 2, {{1, 3, 9}});
    %     val = obj.evaluate(1);

    prefix = string(class(obj));
    pt = helper.chk(pt, prefix + ":InvalidPoint", ...
        "Evaluation point must be a finite real vector with one entry per parameter.", ...
        "numeric", "real", "vector", "finite", "Numel", obj.npar());
    pt = reshape(double(pt), 1, []);
    bounds = obj.GridInfo.Bounds;
    if any(pt < bounds(:, 1).') || any(pt > bounds(:, 2).')
        error(prefix + ":PointOutOfBounds", ...
            "Evaluation point must lie inside the %s grid bounds.", prefix);
    end

    [subs, alpha] = localPoint(obj, pt);
    coeffs = obj.coeffs(subs);
    lbls = obj.lbls();
    weights = ones(1, size(lbls, 1));
    for k = 1:numel(weights)
        for p = 1:numel(alpha)
            j = lbls(k, p);
            deg = obj.Degree(p);
            weights(k) = weights(k) * nchoosek(deg, j) ...
                * (1 - alpha(p))^(deg - j) * alpha(p)^j;
        end
    end

    % A leaf is either one ordinary coefficient row or a rate-vertex table.
    % Reconstructing rows independently preserves symbolic formulas and the
    % package-wide combRows order without consulting assignment metadata.
    rows = cell(1, size(coeffs, 1));
    for row = 1:size(coeffs, 1)
        val = zeros(obj.MatrixSize);
        for k = 1:size(coeffs, 2)
            val = val + coeffs{row, k} .* weights(k);
        end
        rows{row} = val;
    end

    if isscalar(rows)
        out = rows{1};
    else
        out = rows;
    end
end

function [subs, alpha] = localPoint(obj, pt)
    %LOCALPOINT Locate pt with right-cell ownership at interior boundaries.
    nPar = obj.npar();
    subs = zeros(1, nPar);
    alpha = zeros(1, nPar);
    for p = 1:nPar
        grid = obj.GridInfo.Vectors{p};
        x = pt(p);
        if x == grid(end)
            subs(p) = numel(grid) - 1;
        else
            subs(p) = find(grid <= x, 1, "last");
        end

        lo = grid(subs(p));
        hi = grid(subs(p) + 1);
        alpha(p) = (x - lo) / (hi - lo);
    end
end
