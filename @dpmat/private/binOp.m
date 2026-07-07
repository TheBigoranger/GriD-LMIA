function out = binOp(lhs, rhs, fcn, errId)
    %BINOP Apply a same-size binary coefficient operation to dpmat operands.

    if isa(lhs, "dpmat")
        anchor = lhs;
    else
        anchor = rhs;
    end
    grid = anchor.mergeGrid("dpmat:MixedGrid", lhs, rhs);
    reqSize = anchor.MatrixSize;
    ld = asData(grid, lhs, reqSize, errId);
    rd = asData(grid, rhs, reqSize, errId);

    deg = max(ld.Degree, rd.Degree);
    lhsVals = elevVals(anchor, ld.LocalValues, ld.Degree, deg, grid);
    rhsVals = elevVals(anchor, rd.LocalValues, rd.Degree, deg, grid);
    vals = zipVals(anchor, lhsVals, rhsVals, fcn, grid);

    out = dpmat(grid, vals, Degree=deg);
end
