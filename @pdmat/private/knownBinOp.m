function out = knownBinOp(lhs, rhs, fcn, errId)
    %KNOWNBINOP Apply a same-size binary operation to known coefficients.
    %
    %   Syntax:
    %     out = knownBinOp(lhs, rhs, fcn, errId)
    %
    %   Arguments:
    %     lhs, rhs - pdmat or numeric operands.
    %     fcn      - Binary operation applied to aligned coefficients.
    %     errId    - Operation-specific validation identifier.
    %
    %   Output:
    %     out - Coefficient-backed pdmat result.
    %
    %   Example (via public algebra):
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     C = A + 1;
    %
    %   The pdmat operand supplies the dispatch metadata. Inputs are first
    %   moved to its common-refinement grid, then degree-elevated and combined
    %   cell by cell through FCN. Incompatible sizes, grids, or source modes
    %   are rejected by the conversion helpers. An all-zero result is kept in
    %   the compact degree-zero representation.

    if isa(lhs, "pdmat")
        anchor = lhs;
    else
        anchor = rhs;
    end
    % Use one pdmat operand as the metadata anchor for grid and size alignment.
    rb = anchor.pickRateBounds(errId, lhs, rhs);
    grid = anchor.mergeGrid("pdmat:MixedGrid", lhs, rhs);
    reqSize = anchor.MatrixSize;
    ld = normOperand(grid, lhs, reqSize, rb, errId);
    rd = normOperand(grid, rhs, reqSize, rb, errId);

    % Elevate both operands before applying the cell-local coefficient operation.
    deg = max(ld.Degree, rd.Degree);
    data = pdbase.elevData([ld, rd], deg, grid, "fast");
    lhsVals = data(1).LocalValues;
    rhsVals = data(2).LocalValues;
    vals = anchor.zipRateRows(lhsVals, rhsVals, fcn, grid, ...
        "pdmat:InvalidCoefficientRows");

    if helper.isZero(vals, "vals")
        % Store an all-zero result in its compact representation.
        out = zeroObj(grid, reqSize);
        return
    end

    out = mkCoeffObj(grid, vals, deg, rb, [], [], [], "fast", ...
        max(ld.NumRateRows, rd.NumRateRows));
end
