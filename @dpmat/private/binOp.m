function out = binOp(lhs, rhs, fcn, errId)
    %BINOP Apply a same-size binary coefficient operation to dpmat operands.
    %
    %   Syntax:
    %     out = binOp(lhs, rhs, fcn, errId)
    %
    %   Example (via public algebra):
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     C = A + 1;
    %
    %   The dpmat operand supplies the dispatch metadata. Inputs are first
    %   moved to its common-refinement grid, then degree-elevated and combined
    %   cell by cell through FCN. Incompatible sizes, grids, or source modes
    %   are rejected by the conversion helpers. An all-zero result is kept in
    %   the compact degree-zero representation.

    if isa(lhs, "dpmat")
        anchor = lhs;
    else
        anchor = rhs;
    end
    % Use one dpmat operand as the metadata anchor for grid and size alignment.
    grid = anchor.mergeGrid("dpmat:MixedGrid", lhs, rhs);
    reqSize = anchor.MatrixSize;
    ld = asData(grid, lhs, reqSize, errId);
    rd = asData(grid, rhs, reqSize, errId);

    % Elevate both operands before applying the cell-local coefficient operation.
    deg = max(ld.Degree, rd.Degree);
    lhsVals = elevVals(anchor, ld.LocalValues, ld.Degree, deg, grid);
    rhsVals = elevVals(anchor, rd.LocalValues, rd.Degree, deg, grid);
    vals = helper.zipVals(lhsVals, rhsVals, fcn, grid);

    if helper.isZero(vals, "vals")
        % Store an all-zero result in its compact representation.
        out = zeroObj(grid, reqSize);
        return
    end

    out = dpmat(grid, vals, Degree=deg);
end
