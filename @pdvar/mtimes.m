function out = mtimes(lhs, rhs)
    %MTIMES Matrix product for supported pdvar expressions.
    %
    %   Syntax:
    %     C = A * P
    %     C = P * A
    %     C = P * M
    %
    %   Example:
    %     P = pdvar(2, {[0 1]});
    %     A = pdmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    %     C = A * P;

    % Classify special paths before entering general coefficient algebra.
    route = routeProduct(lhs, rhs);
    switch route
        case "zero"
            out = zeroProduct(lhs, rhs);
        case "pdvar-pdvar"
            error("pdvar:InvalidMultiplication", ...
                "pdvar * pdvar is unsupported because it would create quadratic decision terms.");
        case "scalar"
            out = scalarProduct(lhs, rhs);
        case "general"
            out = generalProduct(lhs, rhs);
    end
end

function route = routeProduct(lhs, rhs)
    %ROUTEPRODUCT Select the semantic multiplication path.
    if isa(lhs, "pdvar") && helper.isZero(lhs, "obj") && ...
            (isa(rhs, "pdvar") || isa(rhs, "pdmat") || ...
            (isnumeric(rhs) && ismatrix(rhs) && isreal(rhs) && ...
            ~isempty(rhs) && all(isfinite(rhs(:)))))
        route = "zero";
        return
    end
    if (isa(lhs, "pdvar") || isa(lhs, "pdmat") || ...
            (isnumeric(lhs) && ismatrix(lhs) && isreal(lhs) && ...
            ~isempty(lhs) && all(isfinite(lhs(:))))) && ...
            isa(rhs, "pdvar") && helper.isZero(rhs, "obj")
        route = "zero";
        return
    end
    if (isa(lhs, "pdvar") && helper.isZero(rhs, "num")) || ...
            (helper.isZero(lhs, "num") && isa(rhs, "pdvar"))
        route = "zero";
        return
    end
    if isa(lhs, "pdvar") && isa(rhs, "pdvar")
        route = "pdvar-pdvar";
        return
    end
    if (isa(lhs, "pdvar") && isnumeric(rhs) && isscalar(rhs) && ...
            isreal(rhs) && isfinite(rhs)) || ...
            (isnumeric(lhs) && isscalar(lhs) && isreal(lhs) && ...
            isfinite(lhs) && isa(rhs, "pdvar"))
        route = "scalar";
        return
    end
    route = "general";
end

function out = zeroProduct(lhs, rhs)
    %ZEROPRODUCT Build a compact zero result after route validation.
    if isa(lhs, "pdvar") && helper.isZero(lhs, "obj") && ...
            (isa(rhs, "pdvar") || isa(rhs, "pdmat") || ...
            (isnumeric(rhs) && ismatrix(rhs) && isreal(rhs) && ...
            ~isempty(rhs) && all(isfinite(rhs(:)))))
        grid = lhs.GridInfo.Vectors;
        if isa(rhs, "pdbase")
            grid = lhs.mergeGrid("pdvar:MixedGrid", lhs, rhs);
        end
        if isa(rhs, "pdvar") || isa(rhs, "pdmat")
            rhsSize = rhs.MatrixSize;
        else
            rhsSize = size(rhs);
        end
        out = zeroObj(grid, prodSize(lhs.MatrixSize, rhsSize));
        return
    end
    if (isa(lhs, "pdvar") || isa(lhs, "pdmat") || ...
            (isnumeric(lhs) && ismatrix(lhs) && isreal(lhs) && ...
            ~isempty(lhs) && all(isfinite(lhs(:))))) && ...
            isa(rhs, "pdvar") && helper.isZero(rhs, "obj")
        grid = rhs.GridInfo.Vectors;
        if isa(lhs, "pdbase")
            grid = rhs.mergeGrid("pdvar:MixedGrid", lhs, rhs);
        end
        if isa(lhs, "pdvar") || isa(lhs, "pdmat")
            lhsSize = lhs.MatrixSize;
        else
            lhsSize = size(lhs);
        end
        out = zeroObj(grid, prodSize(lhsSize, rhs.MatrixSize));
        return
    end
    if isa(lhs, "pdvar") && helper.isZero(rhs, "num")
        out = zeroObj(lhs.GridInfo.Vectors, prodSize(lhs.MatrixSize, size(rhs)));
        return
    end
    out = zeroObj(rhs.GridInfo.Vectors, prodSize(size(lhs), rhs.MatrixSize));
end

function out = scalarProduct(lhs, rhs)
    %SCALARPRODUCT Scale a pdvar while preserving rate-row restrictions.
    if isa(lhs, "pdvar")
        obj = lhs;
        scale = rhs;
        leftScale = false;
    else
        obj = rhs;
        scale = lhs;
        leftScale = true;
    end

    if obj.HasRateDependence && ~hasRateRows(obj)
        error("pdvar:InvalidMultiplication", ...
            "Products involving metadata-only rate-dependent pdvar expressions are unsupported in this slice.");
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
    if isa(lhs, "pdvar")
        anchor = lhs;
    elseif isa(rhs, "pdvar")
        anchor = rhs;
    else
        error("pdvar:InvalidMultiplication", "At least one operand must be a pdvar.");
    end

    % Align rate bounds, grids, and coefficient payloads before multiplication.
    rb = pickRb("pdvar:InvalidMultiplication", lhs, rhs);
    grid = anchor.mergeGrid("pdvar:MixedGrid", lhs, rhs);
    ld = asData(grid, lhs, [], rb, "pdvar:InvalidMultiplication");
    rd = asData(grid, rhs, [], rb, "pdvar:InvalidMultiplication");

    % Keep the product inside the affine decision layer.
    if ld.ContainsDecision && rd.ContainsDecision
        error("pdvar:InvalidMultiplication", ...
            "Products may contain decision variables on at most one side.");
    end
    % Allow rate-vertex rows from only one operand.
    if (ld.HasRateDependence || rd.HasRateDependence) && ...
            ~xor(ld.HasRateRows, rd.HasRateRows)
        error("pdvar:InvalidMultiplication", ...
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
    out = pdvar(mkInit(grid, sz, ld.Degree + rd.Degree, vals, ...
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
        error("pdvar:InvalidMultiplication", ...
            "Inner matrix dimensions must agree for pdvar multiplication.");
    end
    sz = [lhs(1), rhs(2)];
end
