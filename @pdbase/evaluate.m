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
        "evaluation point", ...
        "numeric", "real", "vector", "finite", "Numel", obj.npar());
    pt = reshape(double(pt), 1, []);
    bounds = obj.GridInfo.Bounds;
    if any(pt < bounds(:, 1).') || any(pt > bounds(:, 2).')
        error(prefix + ":PointOutOfBounds", ...
            "Evaluation point must lie inside the %s grid bounds.", prefix);
    end

    [subs, alpha] = localPoint(obj, pt);
    coeffs = obj.coeffs(subs);
    % Compute each direction once; kron keeps earlier axes varying slowly,
    % matching combRows without constructing the full tensor-label table.
    weights = 1;
    for p = 1:numel(alpha)
        deg = obj.Degree(p);
        basis = zeros(1, deg + 1);
        for j = 0:deg
            basis(j + 1) = nchoosek(deg, j) ...
                * (1 - alpha(p))^(deg - j) * alpha(p)^j;
        end
        weights = kron(weights, basis);
    end

    % A leaf is either one ordinary coefficient row or a rate-vertex table.
    % Numeric packing keeps rate rows adjacent within each coefficient;
    % symbolic rows retain their formulas without assignment metadata.
    nRows = size(coeffs, 1);
    rows = cell(1, nRows);
    if all(cellfun('isclass', coeffs(:), 'double'))
        % Two-dimensional packing also supports sparse double coefficients.
        % Other payload types retain their arithmetic without coercion.
        packed = reshape(horzcat(coeffs{:}), [], numel(weights));
        vals = reshape(packed * weights(:), [], nRows);
        for row = 1:nRows
            rows{row} = reshape(vals(:, row), obj.MatrixSize);
        end
    else
        for row = 1:nRows
            val = zeros(obj.MatrixSize);
            for k = 1:size(coeffs, 2)
                val = val + coeffs{row, k} .* weights(k);
            end
            rows{row} = val;
        end
    end

    % A fixed rate box still has one active row; only ordinary data is unboxed.
    if obj.NumRateRows == 0
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
