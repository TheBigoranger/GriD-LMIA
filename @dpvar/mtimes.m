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

    % Classify special paths before entering general coefficient algebra.
    route = routeProduct(lhs, rhs);
    switch route
        case "zero"
            out = zeroProduct(lhs, rhs);
        case "dpvar-dpvar"
            error("dpvar:InvalidMultiplication", ...
                "dpvar * dpvar is unsupported because it would create quadratic decision terms.");
        case "scalar"
            out = scalarProduct(lhs, rhs);
        case "general"
            out = generalProduct(lhs, rhs);
    end
end

function route = routeProduct(lhs, rhs)
    %ROUTEPRODUCT Select the semantic multiplication path.
    if isa(lhs, "dpvar") && helper.isZero(lhs, "obj") && ...
            (isa(rhs, "dpvar") || isa(rhs, "dpmat") || ...
            (isnumeric(rhs) && ismatrix(rhs) && isreal(rhs) && ...
            ~isempty(rhs) && all(isfinite(rhs(:)))))
        route = "zero";
        return
    end
    if (isa(lhs, "dpvar") || isa(lhs, "dpmat") || ...
            (isnumeric(lhs) && ismatrix(lhs) && isreal(lhs) && ...
            ~isempty(lhs) && all(isfinite(lhs(:))))) && ...
            isa(rhs, "dpvar") && helper.isZero(rhs, "obj")
        route = "zero";
        return
    end
    if (isa(lhs, "dpvar") && helper.isZero(rhs, "num")) || ...
            (helper.isZero(lhs, "num") && isa(rhs, "dpvar"))
        route = "zero";
        return
    end
    if isa(lhs, "dpvar") && isa(rhs, "dpvar")
        route = "dpvar-dpvar";
        return
    end
    if (isa(lhs, "dpvar") && isnumeric(rhs) && isscalar(rhs) && ...
            isreal(rhs) && isfinite(rhs)) || ...
            (isnumeric(lhs) && isscalar(lhs) && isreal(lhs) && ...
            isfinite(lhs) && isa(rhs, "dpvar"))
        route = "scalar";
        return
    end
    route = "general";
end

function out = zeroProduct(lhs, rhs)
    %ZEROPRODUCT Build a compact zero result after route validation.
    if isa(lhs, "dpvar") && helper.isZero(lhs, "obj") && ...
            (isa(rhs, "dpvar") || isa(rhs, "dpmat") || ...
            (isnumeric(rhs) && ismatrix(rhs) && isreal(rhs) && ...
            ~isempty(rhs) && all(isfinite(rhs(:)))))
        grid = lhs.GridInfo.Vectors;
        if isa(rhs, "dpbase")
            grid = lhs.mergeGrid("dpvar:MixedGrid", lhs, rhs);
        end
        if isa(rhs, "dpvar") || isa(rhs, "dpmat")
            rhsSize = rhs.MatrixSize;
        else
            rhsSize = size(rhs);
        end
        out = zeroObj(grid, prodSize(lhs.MatrixSize, rhsSize));
        return
    end
    if (isa(lhs, "dpvar") || isa(lhs, "dpmat") || ...
            (isnumeric(lhs) && ismatrix(lhs) && isreal(lhs) && ...
            ~isempty(lhs) && all(isfinite(lhs(:))))) && ...
            isa(rhs, "dpvar") && helper.isZero(rhs, "obj")
        grid = rhs.GridInfo.Vectors;
        if isa(lhs, "dpbase")
            grid = rhs.mergeGrid("dpvar:MixedGrid", lhs, rhs);
        end
        if isa(lhs, "dpvar") || isa(lhs, "dpmat")
            lhsSize = lhs.MatrixSize;
        else
            lhsSize = size(lhs);
        end
        out = zeroObj(grid, prodSize(lhsSize, rhs.MatrixSize));
        return
    end
    if isa(lhs, "dpvar") && helper.isZero(rhs, "num")
        out = zeroObj(lhs.GridInfo.Vectors, prodSize(lhs.MatrixSize, size(rhs)));
        return
    end
    out = zeroObj(rhs.GridInfo.Vectors, prodSize(size(lhs), rhs.MatrixSize));
end

function out = scalarProduct(lhs, rhs)
    %SCALARPRODUCT Scale a dpvar while preserving rate-row restrictions.
    if isa(lhs, "dpvar")
        obj = lhs;
        scale = rhs;
        leftScale = false;
    else
        obj = rhs;
        scale = lhs;
        leftScale = true;
    end

    if obj.HasRateDependence && ~hasRateRows(obj)
        error("dpvar:InvalidMultiplication", ...
            "Products involving metadata-only rate-dependent dpvar expressions are unsupported in this slice.");
    end
    if helper.isZero(obj, "obj")
        out = zeroObj(obj.GridInfo.Vectors, obj.MatrixSize);
    elseif leftScale
        out = unOp(obj, @(a) scale * a);
    else
        out = unOp(obj, @(a) a * scale);
    end
end

function out = generalProduct(lhs, rhs)
    %GENERALPRODUCT Align operands and multiply local Bernstein rows.
    if isa(lhs, "dpvar")
        anchor = lhs;
    elseif isa(rhs, "dpvar")
        anchor = rhs;
    else
        error("dpvar:InvalidMultiplication", "At least one operand must be a dpvar.");
    end

    % Align rate bounds, grids, and coefficient payloads before multiplication.
    rb = pickRb("dpvar:InvalidMultiplication", lhs, rhs);
    grid = anchor.mergeGrid("dpvar:MixedGrid", lhs, rhs);
    ld = asData(grid, lhs, [], rb, "dpvar:InvalidMultiplication");
    rd = asData(grid, rhs, [], rb, "dpvar:InvalidMultiplication");

    % Keep the product inside the affine decision layer.
    if ld.ContainsDecision && rd.ContainsDecision
        error("dpvar:InvalidMultiplication", ...
            "Products may contain decision variables on at most one side.");
    end
    % Allow rate-vertex rows from only one operand.
    if (ld.HasRateDependence || rd.HasRateDependence) && ...
            ~xor(ld.HasRateRows, rd.HasRateRows)
        error("dpvar:InvalidMultiplication", ...
            "Products may contain derivative rate vertices on exactly one known-data side.");
    end

    sz = prodSize(ld.MatrixSize, rd.MatrixSize);
    % Multiply local rows while broadcasting ordinary rows as needed.
    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) prodRows(anchor, ...
        helper.cellGet(ld.LocalValues, subs), ld.Degree, ...
        helper.cellGet(rd.LocalValues, subs), rd.Degree));

    hasRate = ld.HasRateDependence || rd.HasRateDependence;
    if ~hasRate
        % Ordinary products do not retain rate bounds.
        rb = [];
    end
    out = dpvar(mkInit(grid, sz, ld.Degree + rd.Degree, vals, ...
        ld.ContainsDecision || rd.ContainsDecision, hasRate, rb, ...
        "expression", ld.IsContinuous && rd.IsContinuous));
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
