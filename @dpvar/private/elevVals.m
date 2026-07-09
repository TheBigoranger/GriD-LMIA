function vals = elevVals(obj, vals, fromDeg, toDeg, grid)
    %ELEVVALS Degree-elevate every physical cell in a LocalValues tree.
    %
    %   Syntax:
    %     vals = elevVals(obj, vals, fromDeg, toDeg, grid)
    %
    %   Example (via public algebra):
    %     P0 = dpvar(1, {[0 1]}, Degree=0);
    %     P1 = dpvar(1, {[0 1]});
    %     C = P0 + P1;  % Elevates P0 before combining coefficients.
    %
    %   Ordinary leaves are flat coefficient cells. Rate-affine leaves are
    %   row-by-coefficient cell tables, so each rate row must be elevated
    %   independently while preserving its vertex ordering.

    if fromDeg == toDeg
        return
    end
    if nargin < 5
        grid = obj.GridInfo.Vectors;
    end

    nCell = cellfun(@numel, grid) - 1;
    nCoeff = (fromDeg + 1) ^ numel(grid);
    hasRows = isRateRows(vals, grid, nCoeff);
    vals = helper.mkNest(nCell, @(subs) elevCell(obj, ...
        helper.cellGet(vals, subs), fromDeg, toDeg, hasRows));
end

function coeffs = elevCell(obj, coeffs, fromDeg, toDeg, hasRows)
    %ELEVCELL Elevate one ordinary leaf or every row of one rate leaf.
    %
    %   Syntax:
    %     coeffs = elevCell(obj, coeffs, fromDeg, toDeg, hasRows)
    %
    %   The row count is metadata for rate vertices, not a polynomial degree;
    %   only the coefficient columns change during this operation.
    if ~hasRows
        coeffs = obj.bernElev(coeffs, fromDeg, toDeg);
        return
    end

    nRows = size(coeffs, 1);
    nCoeff = (toDeg + 1) ^ obj.npar();
    out = cell(nRows, nCoeff);
    for row = 1:nRows
        out(row, :) = obj.bernElev(coeffs(row, :), fromDeg, toDeg);
    end
    coeffs = out;
end
