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
    if (isa(lhs, "dpvar") && lhs.HasRateDependence) || ...
            (isa(rhs, "dpvar") && rhs.HasRateDependence)
        error("dpvar:InvalidMultiplication", ...
            "Products involving rate-dependent dpvar expressions are unsupported in this slice.");
    end

    if isa(lhs, "dpvar") && isScalarNum(rhs)
        out = unOp(lhs, @(a) a * rhs);
        return
    end
    if isScalarNum(lhs) && isa(rhs, "dpvar")
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

    grid = anchor.mergeGrid("dpvar:MixedGrid", lhs, rhs);
    ld = asData(grid, lhs, [], anchor.RateBounds, "dpvar:InvalidMultiplication");
    rd = asData(grid, rhs, [], anchor.RateBounds, "dpvar:InvalidMultiplication");

    if ld.ContainsDecision && rd.ContainsDecision
        error("dpvar:InvalidMultiplication", ...
            "Products may contain decision variables on at most one side.");
    end
    if ld.HasRateDependence || rd.HasRateDependence
        error("dpvar:InvalidMultiplication", ...
            "Products involving rate-dependent dpvar expressions are unsupported in this slice.");
    end
    if ld.MatrixSize(2) ~= rd.MatrixSize(1)
        error("dpvar:InvalidMultiplication", ...
            "Inner matrix dimensions must agree for dpvar multiplication.");
    end

    nCell = cellfun(@numel, grid) - 1;
    vals = internal.mkNest(nCell, @(subs) anchor.bernProd( ...
        internal.cellGet(ld.LocalValues, subs), ld.Degree, ...
        internal.cellGet(rd.LocalValues, subs), rd.Degree));

    sz = [ld.MatrixSize(1), rd.MatrixSize(2)];
    out = dpvar(mkInit(grid, sz, ld.Degree + rd.Degree, vals, ...
        ld.ContainsDecision || rd.ContainsDecision, false, [], "expression"));
end

function tf = isScalarNum(val)
    tf = isnumeric(val) && isscalar(val) && isreal(val) && isfinite(val);
end
