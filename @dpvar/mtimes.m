function out = mtimes(lhs, rhs)
    %MTIMES Matrix product for supported dpvar expressions.
    %
    %   Syntax:
    %     C = A * P
    %     C = P * A
    %     C = P * M
    %
    %   Example:
    %     P = dpvar(2, {[0 1]});
    %     A = dpmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    %     C = A * P;

    if isa(lhs, "dpvar") && isa(rhs, "dpvar")
        error("dpvar:InvalidMultiplication", ...
            "dpvar * dpvar is unsupported because it would create quadratic decision terms.");
    end

    if isa(lhs, "dpvar") && isScalarNum(rhs)
        if lhs.HasRateDependence && ~hasRateRows(lhs)
            error("dpvar:InvalidMultiplication", ...
                "Products involving metadata-only rate-dependent dpvar expressions are unsupported in this slice.");
        end
        out = unOp(lhs, @(a) a * rhs);
        return
    end
    if isScalarNum(lhs) && isa(rhs, "dpvar")
        if rhs.HasRateDependence && ~hasRateRows(rhs)
            error("dpvar:InvalidMultiplication", ...
                "Products involving metadata-only rate-dependent dpvar expressions are unsupported in this slice.");
        end
        out = unOp(rhs, @(a) lhs * a);
        return
    end

    if isa(lhs, "dpvar")
        anchor = lhs;
    elseif isa(rhs, "dpvar")
        anchor = rhs;
    else
        error("dpvar:InvalidMultiplication", "At least one operand must be a dpvar.");
    end

    allowEmptyRate = hasRateRows(lhs) || hasRateRows(rhs);
    rb = opRateBounds(allowEmptyRate, lhs, rhs);
    grid = anchor.mergeGrid("dpvar:MixedGrid", lhs, rhs);
    ld = asData(grid, lhs, [], rb, "dpvar:InvalidMultiplication", allowEmptyRate);
    rd = asData(grid, rhs, [], rb, "dpvar:InvalidMultiplication", allowEmptyRate);

    if ld.ContainsDecision && rd.ContainsDecision
        error("dpvar:InvalidMultiplication", ...
            "Products may contain decision variables on at most one side.");
    end
    if (ld.HasRateDependence || rd.HasRateDependence) && ...
            ~xor(ld.HasRateRows, rd.HasRateRows)
        error("dpvar:InvalidMultiplication", ...
            "Products may contain derivative rate vertices on exactly one known-data side.");
    end
    if ld.MatrixSize(2) ~= rd.MatrixSize(1)
        error("dpvar:InvalidMultiplication", ...
            "Inner matrix dimensions must agree for dpvar multiplication.");
    end

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) prodRows(anchor, ...
        helper.cellGet(ld.LocalValues, subs), ld.Degree, ...
        helper.cellGet(rd.LocalValues, subs), rd.Degree));

    sz = [ld.MatrixSize(1), rd.MatrixSize(2)];
    hasRate = ld.HasRateDependence || rd.HasRateDependence;
    if ~hasRate
        rb = [];
    end
    out = dpvar(mkInit(grid, sz, ld.Degree + rd.Degree, vals, ...
        ld.ContainsDecision || rd.ContainsDecision, hasRate, rb, ...
        "expression", ld.IsContinuous && rd.IsContinuous));
end

function tf = isScalarNum(val)
    tf = isnumeric(val) && isscalar(val) && isreal(val) && isfinite(val);
end

function tf = hasRateRows(val)
    tf = false;
    if isa(val, "dpvar")
        nCoeff = (val.Degree + 1) ^ val.npar();
        tf = isRateRows(val.LocalValues, val.GridInfo.Vectors, nCoeff);
    end
end

function rb = opRateBounds(allowEmptyRate, varargin)
    rb = [];
    for k = 1:numel(varargin)
        val = varargin{k};
        if ~isa(val, "dpvar") || isempty(val.RateBounds)
            continue
        end
        if isempty(rb)
            rb = val.RateBounds;
        elseif ~isequal(rb, val.RateBounds)
            error("dpvar:InvalidMultiplication", ...
                "dpvar operands must have matching RateBounds.");
        end
    end
    if allowEmptyRate && isempty(rb)
        error("dpvar:InvalidMultiplication", ...
            "Rate-vertex dpvar expressions require RateBounds.");
    end
end
