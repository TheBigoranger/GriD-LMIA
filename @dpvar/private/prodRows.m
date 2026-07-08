function coeffs = prodRows(obj, lhs, lhsDeg, rhs, rhsDeg)
    %PRODROWS Multiply ordinary Bernstein rows with one rate-vertex table.

    lhsRate = size(lhs, 1) > 1;
    rhsRate = size(rhs, 1) > 1;
    if lhsRate && rhsRate
        error("dpvar:InvalidMultiplication", ...
            "Products may contain rate-vertex dependence on at most one side.");
    end

    if ~lhsRate && ~rhsRate
        coeffs = obj.bernProd(lhs, lhsDeg, rhs, rhsDeg);
        return
    end

    nRows = max(size(lhs, 1), size(rhs, 1));
    nCoeff = (lhsDeg + rhsDeg + 1) ^ obj.npar();
    coeffs = cell(nRows, nCoeff);
    for row = 1:nRows
        lhsRow = min(row, size(lhs, 1));
        rhsRow = min(row, size(rhs, 1));
        coeffs(row, :) = obj.bernProd(lhs(lhsRow, :), lhsDeg, ...
            rhs(rhsRow, :), rhsDeg);
    end
end
