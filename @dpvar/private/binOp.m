function out = binOp(lhs, rhs, fcn, errId)
    %BINOP Apply common-refinement affine binary coefficient operations.

    if isa(lhs, "dpvar")
        anchor = lhs;
    elseif isa(rhs, "dpvar")
        anchor = rhs;
    else
        error(errId, "At least one operand must be a dpvar.");
    end

    allowEmptyRate = hasRateRows(lhs) || hasRateRows(rhs);
    rb = opRateBounds(allowEmptyRate, errId, lhs, rhs);
    grid = anchor.mergeGrid("dpvar:MixedGrid", lhs, rhs);
    reqSize = anchor.MatrixSize;
    ld = asData(grid, lhs, reqSize, rb, errId, allowEmptyRate);
    rd = asData(grid, rhs, reqSize, rb, errId, allowEmptyRate);

    deg = max(ld.Degree, rd.Degree);
    lhsVals = elevVals(anchor, ld.LocalValues, ld.Degree, deg, grid);
    rhsVals = elevVals(anchor, rd.LocalValues, rd.Degree, deg, grid);
    vals = zipRows(lhsVals, rhsVals, fcn, grid);

    hasRate = ld.HasRateDependence || rd.HasRateDependence;
    if ~hasRate
        rb = [];
    end

    out = dpvar(mkInit(grid, reqSize, deg, vals, ...
        ld.ContainsDecision || rd.ContainsDecision, ...
        hasRate, rb, "expression", ld.IsContinuous && rd.IsContinuous));
end

function tf = hasRateRows(val)
    tf = false;
    if isa(val, "dpvar")
        nCoeff = (val.Degree + 1) ^ val.npar();
        tf = isRateRows(val.LocalValues, val.GridInfo.Vectors, nCoeff);
    end
end

function rb = opRateBounds(allowEmptyRate, errId, varargin)
    rb = [];
    for k = 1:numel(varargin)
        val = varargin{k};
        if ~isa(val, "dpvar") || isempty(val.RateBounds)
            continue
        end
        if isempty(rb)
            rb = val.RateBounds;
        elseif ~isequal(rb, val.RateBounds)
            error(errId, "dpvar operands must have matching RateBounds.");
        end
    end
    if allowEmptyRate && isempty(rb)
        error(errId, "Rate-vertex dpvar expressions require RateBounds.");
    end
end
