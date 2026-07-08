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

    if isa(lhs, "dpvar") && isZeroObj(lhs) && hasProdSize(rhs)
        grid = prodGrid(lhs, rhs);
        out = zeroObj(grid, prodSize(lhs.MatrixSize, opSize(rhs)));
        return
    end
    if hasProdSize(lhs) && isa(rhs, "dpvar") && isZeroObj(rhs)
        grid = prodGrid(rhs, lhs);
        out = zeroObj(grid, prodSize(opSize(lhs), rhs.MatrixSize));
        return
    end
    if isa(lhs, "dpvar") && isZeroNum(rhs)
        out = zeroObj(lhs.GridInfo.Vectors, prodSize(lhs.MatrixSize, size(rhs)));
        return
    end
    if isZeroNum(lhs) && isa(rhs, "dpvar")
        out = zeroObj(rhs.GridInfo.Vectors, prodSize(size(lhs), rhs.MatrixSize));
        return
    end
    if isa(lhs, "dpvar") && isa(rhs, "dpmat") && isZeroKnown(rhs)
        grid = lhs.mergeGrid("dpvar:MixedGrid", lhs, rhs);
        out = zeroObj(grid, prodSize(lhs.MatrixSize, rhs.MatrixSize));
        return
    end
    if isa(lhs, "dpmat") && isZeroKnown(lhs) && isa(rhs, "dpvar")
        grid = rhs.mergeGrid("dpvar:MixedGrid", lhs, rhs);
        out = zeroObj(grid, prodSize(lhs.MatrixSize, rhs.MatrixSize));
        return
    end

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

    rb = pickRb("dpvar:InvalidMultiplication", lhs, rhs);
    grid = anchor.mergeGrid("dpvar:MixedGrid", lhs, rhs);
    ld = asData(grid, lhs, [], rb, "dpvar:InvalidMultiplication");
    rd = asData(grid, rhs, [], rb, "dpvar:InvalidMultiplication");

    if ld.ContainsDecision && rd.ContainsDecision
        error("dpvar:InvalidMultiplication", ...
            "Products may contain decision variables on at most one side.");
    end
    if (ld.HasRateDependence || rd.HasRateDependence) && ...
            ~xor(ld.HasRateRows, rd.HasRateRows)
        error("dpvar:InvalidMultiplication", ...
            "Products may contain derivative rate vertices on exactly one known-data side.");
    end
    sz = prodSize(ld.MatrixSize, rd.MatrixSize);

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) prodRows(anchor, ...
        helper.cellGet(ld.LocalValues, subs), ld.Degree, ...
        helper.cellGet(rd.LocalValues, subs), rd.Degree));

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

function tf = hasProdSize(val)
    tf = isa(val, "dpvar") || isa(val, "dpmat") || isnumeric(val);
end

function sz = opSize(val)
    if isa(val, "dpvar") || isa(val, "dpmat")
        sz = val.MatrixSize;
    else
        sz = size(val);
    end
end

function grid = prodGrid(anchor, other)
    grid = anchor.GridInfo.Vectors;
    if isa(other, "dpbase")
        grid = anchor.mergeGrid("dpvar:MixedGrid", anchor, other);
    end
end

function sz = prodSize(lhs, rhs)
    lhsScalar = isequal(lhs, [1 1]);
    rhsScalar = isequal(rhs, [1 1]);
    if lhsScalar
        sz = rhs;
        return
    end
    if rhsScalar
        sz = lhs;
        return
    end
    if lhs(2) ~= rhs(1)
        error("dpvar:InvalidMultiplication", ...
            "Inner matrix dimensions must agree for dpvar multiplication.");
    end
    sz = [lhs(1), rhs(2)];
end
