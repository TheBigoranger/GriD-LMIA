function vals = elevVals(obj, vals, fromDeg, toDeg, grid)
    %ELEVVALS Degree-elevate every physical cell in a LocalValues tree.

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
