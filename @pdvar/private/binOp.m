function out = binOp(lhs, rhs, fcn, errId)
    %BINOP Apply common-refinement affine binary coefficient operations.
    %
    %   Syntax:
    %     out = binOp(lhs, rhs, fcn, errId)
    %
    %   Example (via public algebra):
    %     P = pdvar(1, {[0 1]});
    %     C = P + 1;
    %
    %   One pdvar operand anchors dispatch, grid metadata, and output size.
    %   The operands are converted, degree-elevated, and combined cell by
    %   cell; rate rows are broadcast only when their stored vertex counts
    %   permit it. RateBounds must agree whenever rate dependence is present.
    %   Zero results use the compact degree-zero representation.

    if isa(lhs, "pdvar")
        anchor = lhs;
    elseif isa(rhs, "pdvar")
        anchor = rhs;
    else
        error(errId, "At least one operand must be a pdvar.");
    end

    rb = pickRb(errId, lhs, rhs);
    % Merge physical cells before fitting coefficients so both operands use
    % one local Bernstein basis for the binary operation.
    grid = anchor.mergeGrid("pdvar:MixedGrid", lhs, rhs);
    reqSize = anchor.MatrixSize;
    ld = asData(grid, lhs, reqSize, rb, errId);
    rd = asData(grid, rhs, reqSize, rb, errId);

    deg = max(ld.Degree, rd.Degree);
    % Degree elevation changes representation only; it does not change the
    % represented polynomial before coefficient-wise algebra is applied.
    lhsVals = elevLocalValues(anchor, ld.LocalValues, ld.Degree, deg, grid);
    rhsVals = elevLocalValues(anchor, rd.LocalValues, rd.Degree, deg, grid);
    vals = zipRows(lhsVals, rhsVals, fcn, grid);

    if helper.isZero(vals, "vals")
        out = zeroObj(grid, reqSize);
        return
    end

    hasRate = ld.HasRateDependence || rd.HasRateDependence;
    if ~hasRate
        rb = [];
    end

    out = pdvar(mkInit(grid, reqSize, deg, vals, ...
        ld.ContainsDecision || rd.ContainsDecision, ...
        hasRate, rb, "expression", ld.IsContinuous && rd.IsContinuous));
end
