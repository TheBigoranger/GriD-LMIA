function out = affineBinOp(lhs, rhs, fcn, errId)
    %AFFINEBINOP Apply common-refinement affine coefficient operations.
    %
    %   Syntax:
    %     out = affineBinOp(lhs, rhs, fcn, errId)
    %
    %   Arguments:
    %     lhs, rhs - Supported operands with at least one pdvar.
    %     fcn      - Binary mapping applied to aligned coefficients.
    %     errId    - Operation-specific validation identifier.
    %
    %   Output:
    %     out - Affine pdvar result on the common grid and degree.
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

    rb = anchor.pickRateBounds(errId, lhs, rhs);
    % Merge physical cells before fitting coefficients so both operands use
    % one local Bernstein basis for the binary operation.
    grid = anchor.mergeGrid("pdvar:MixedGrid", lhs, rhs);
    reqSize = anchor.MatrixSize;
    ld = normOperand(grid, lhs, reqSize, rb, errId);
    rd = normOperand(grid, rhs, reqSize, rb, errId);

    deg = max(ld.Degree, rd.Degree);
    % Degree elevation changes representation only; it does not change the
    % represented polynomial before coefficient-wise algebra is applied.
    data = pdbase.elevData([ld, rd], deg, grid, "fast");
    lhsVals = data(1).LocalValues;
    rhsVals = data(2).LocalValues;
    vals = anchor.zipRateRows(lhsVals, rhsVals, fcn, grid, ...
        "pdvar:InvalidCoefficientRows");

    if helper.isZero(vals, "vals")
        out = zeroObj(grid, reqSize);
        return
    end

    out = pdvar(mkCtorState(grid, reqSize, deg, vals, ...
        ld.ContainsDecision || rd.ContainsDecision, ...
        rb, "expression", [], "fast", ...
        max(ld.NumRateRows, rd.NumRateRows)));
end
