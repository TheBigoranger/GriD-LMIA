function coeffs = prodRows(obj, lhs, lhsDeg, rhs, rhsDeg)
    %PRODROWS Multiply ordinary Bernstein rows with one rate-vertex table.
    %
    %   Syntax:
    %     coeffs = prodRows(obj, lhs, lhsDeg, rhs, rhsDeg)
    %
    %   Arguments:
    %     lhs, rhs       - Ordinary or rate-vertex coefficient tables.
    %     lhsDeg, rhsDeg - Scalar Bernstein degrees of those tables.
    %
    %   Output:
    %     coeffs - Product table with ordinary rows broadcast as needed.
    %
    %   Example (via public algebra):
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    %     C = rhodiff(P) * A;
    %
    %   At most one input may contain multiple rate rows because quadratic
    %   rate dependence is outside the current package scope. A one-row input
    %   is broadcast, while Bernstein coefficient products determine the
    %   output degree and column count.

    lhsRate = size(lhs, 1) > 1;
    rhsRate = size(rhs, 1) > 1;
    if lhsRate && rhsRate
        error("pdvar:InvalidMultiplication", ...
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
