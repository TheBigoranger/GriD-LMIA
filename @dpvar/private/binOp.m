function out = binOp(lhs, rhs, fcn, errId)
    %BINOP Apply common-refinement affine binary coefficient operations.

    if isa(lhs, "dpvar")
        anchor = lhs;
    elseif isa(rhs, "dpvar")
        anchor = rhs;
    else
        error(errId, "At least one operand must be a dpvar.");
    end

    grid = anchor.mergeGrid("dpvar:MixedGrid", lhs, rhs);
    reqSize = anchor.MatrixSize;
    ld = asData(grid, lhs, reqSize, anchor.RateBounds, errId);
    rd = asData(grid, rhs, reqSize, anchor.RateBounds, errId);

    deg = max(ld.Degree, rd.Degree);
    lhsVals = elevVals(anchor, ld.LocalValues, ld.Degree, deg, grid);
    rhsVals = elevVals(anchor, rd.LocalValues, rd.Degree, deg, grid);
    vals = internal.zipVals(lhsVals, rhsVals, fcn, grid);

    out = dpvar(mkInit(grid, reqSize, deg, vals, ...
        ld.ContainsDecision || rd.ContainsDecision, ...
        ld.HasRateDependence || rd.HasRateDependence, ...
        anchor.RateBounds, ...
        "expression"));
end
