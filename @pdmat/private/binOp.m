function out = binOp(lhs, rhs, fcn, errId)
    %BINOP Apply a same-size binary coefficient operation to pdmat operands.
    %
    %   Syntax:
    %     out = binOp(lhs, rhs, fcn, errId)
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
    grid = anchor.mergeGrid("pdmat:MixedGrid", lhs, rhs);
    reqSize = anchor.MatrixSize;
    ld = asData(grid, lhs, reqSize, errId);
    rd = asData(grid, rhs, reqSize, errId);

    % Elevate both operands before applying the cell-local coefficient operation.
    deg = max(ld.Degree, rd.Degree);
    lhsVals = pdbase.elevLocalValues(ld.LocalValues, ld.Degree, deg, grid);
    rhsVals = pdbase.elevLocalValues(rd.LocalValues, rd.Degree, deg, grid);
    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) cellfun(fcn, ...
        helper.cellGet(lhsVals, subs), helper.cellGet(rhsVals, subs), ...
        UniformOutput=false));

    if helper.isZero(vals, "vals")
        % Store an all-zero result in its compact representation.
        out = zeroObj(grid, reqSize);
        return
    end

    out = mkObj(grid, vals, deg);
end
