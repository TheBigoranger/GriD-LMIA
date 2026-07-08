function out = binOp(lhs, rhs, fcn, errId)
    %BINOP Apply common-refinement affine binary coefficient operations.

    if isa(lhs, "dpvar")
        anchor = lhs;
    elseif isa(rhs, "dpvar")
        anchor = rhs;
    else
        error(errId, "At least one operand must be a dpvar.");
    end

    rb = pickRb(errId, lhs, rhs);
    grid = anchor.mergeGrid("dpvar:MixedGrid", lhs, rhs);
    reqSize = anchor.MatrixSize;
    ld = asData(grid, lhs, reqSize, rb, errId);
    rd = asData(grid, rhs, reqSize, rb, errId);

    deg = max(ld.Degree, rd.Degree);
    lhsVals = elevVals(anchor, ld.LocalValues, ld.Degree, deg, grid);
    rhsVals = elevVals(anchor, rd.LocalValues, rd.Degree, deg, grid);
    vals = zipRows(lhsVals, rhsVals, fcn, grid);

    if isZeroVals(vals)
        out = zeroObj(grid, reqSize);
        return
    end

    hasRate = ld.HasRateDependence || rd.HasRateDependence;
    if ~hasRate
        rb = [];
    end

    out = dpvar(mkInit(grid, reqSize, deg, vals, ...
        ld.ContainsDecision || rd.ContainsDecision, ...
        hasRate, rb, "expression", ld.IsContinuous && rd.IsContinuous));
end
