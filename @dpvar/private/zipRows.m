function vals = zipRows(lhsVals, rhsVals, fcn, grid)
    %ZIPROWS Combine ordinary rows with rate-vertex coefficient tables.

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) zipCell( ...
        helper.cellGet(lhsVals, subs), helper.cellGet(rhsVals, subs), fcn));
end

function coeffs = zipCell(lhs, rhs, fcn)
    nCoeff = size(lhs, 2);
    if size(rhs, 2) ~= nCoeff
        error("dpvar:InvalidCoefficientRows", ...
            "Coefficient rows must have matching column counts.");
    end

    nRows = max(size(lhs, 1), size(rhs, 1));
    if size(lhs, 1) ~= nRows && size(lhs, 1) ~= 1
        error("dpvar:InvalidCoefficientRows", ...
            "Left coefficient rows cannot be broadcast to the rate vertices.");
    end
    if size(rhs, 1) ~= nRows && size(rhs, 1) ~= 1
        error("dpvar:InvalidCoefficientRows", ...
            "Right coefficient rows cannot be broadcast to the rate vertices.");
    end

    coeffs = cell(nRows, nCoeff);
    for row = 1:nRows
        lhsRow = min(row, size(lhs, 1));
        rhsRow = min(row, size(rhs, 1));
        for c = 1:nCoeff
            coeffs{row, c} = fcn(lhs{lhsRow, c}, rhs{rhsRow, c});
        end
    end
end
