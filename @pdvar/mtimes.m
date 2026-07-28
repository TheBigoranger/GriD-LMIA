function out = mtimes(lhs, rhs)
    %MTIMES Matrix product for supported pdvar expressions.
    %
    %   Syntax:
    %     C = A * P
    %     C = P * A
    %     C = P * M
    %
    %   Arguments:
    %     lhs, rhs - Compatible pdvar, pdmat, or finite numeric operands.
    %
    %   Output:
    %     C - Affine cell-local product with at most one decision/rate side.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]});
    %     A = pdmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    %     C = A * P;

    % Classify special paths before entering general coefficient algebra.
    route = routeProd(lhs, rhs);
    switch route
        case "zero"
            out = zeroProd(lhs, rhs);
        case "pdvar-pdvar"
            error("pdvar:InvalidMultiplication", ...
                "pdvar * pdvar is unsupported because it would create quadratic decision terms.");
        case "scalar"
            out = scalarProd(lhs, rhs);
        case "general"
            out = generalProd(lhs, rhs);
    end
end

function route = routeProd(lhs, rhs)
    %ROUTEPROD Select the semantic multiplication path.
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

function out = zeroProd(lhs, rhs)
    %ZEROPROD Build a compact zero result after route validation.
    if isa(lhs, "pdvar") && helper.isZero(lhs, "obj") && ...
            (isa(rhs, "pdvar") || isa(rhs, "pdmat") || ...
            (isnumeric(rhs) && ismatrix(rhs) && isreal(rhs) && ...
            ~isempty(rhs) && all(isfinite(rhs(:)))))
        grid = lhs.GridInfo.Vectors;
        if isa(rhs, "pdbase")
            rb = lhs.pickRateBounds("pdvar:InvalidMultiplication", rhs);
            grid = lhs.mergeGrid("pdvar:MixedGrid", lhs, rhs);
            if lhs.hasRateRows() || rhs.hasRateRows()
                asData(grid, lhs, [], rb, "pdvar:InvalidMultiplication");
                asData(grid, rhs, [], rb, "pdvar:InvalidMultiplication");
            end
        end
        if isa(rhs, "pdvar") || isa(rhs, "pdmat")
            rhsSize = rhs.MatrixSize;
        else
            rhsSize = size(rhs);
        end
        out = zeroObj(grid, prodSz(lhs.MatrixSize, rhsSize));
        return
    end
    if (isa(lhs, "pdvar") || isa(lhs, "pdmat") || ...
            (isnumeric(lhs) && ismatrix(lhs) && isreal(lhs) && ...
            ~isempty(lhs) && all(isfinite(lhs(:))))) && ...
            isa(rhs, "pdvar") && helper.isZero(rhs, "obj")
        grid = rhs.GridInfo.Vectors;
        if isa(lhs, "pdbase")
            rb = rhs.pickRateBounds("pdvar:InvalidMultiplication", lhs);
            grid = rhs.mergeGrid("pdvar:MixedGrid", lhs, rhs);
            if lhs.hasRateRows() || rhs.hasRateRows()
                asData(grid, lhs, [], rb, "pdvar:InvalidMultiplication");
                asData(grid, rhs, [], rb, "pdvar:InvalidMultiplication");
            end
        end
        if isa(lhs, "pdvar") || isa(lhs, "pdmat")
            lhsSize = lhs.MatrixSize;
        else
            lhsSize = size(lhs);
        end
        out = zeroObj(grid, prodSz(lhsSize, rhs.MatrixSize));
        return
    end
    if isa(lhs, "pdvar") && helper.isZero(rhs, "num")
        out = zeroObj(lhs.GridInfo.Vectors, prodSz(lhs.MatrixSize, size(rhs)));
        return
    end
    out = zeroObj(rhs.GridInfo.Vectors, prodSz(size(lhs), rhs.MatrixSize));
end

function out = scalarProd(lhs, rhs)
    %SCALARPROD Scale a pdvar while preserving rate-row restrictions.
    if isa(lhs, "pdvar")
        obj = lhs;
        scale = rhs;
        leftScale = false;
    else
        obj = rhs;
        scale = lhs;
        leftScale = true;
    end

    if obj.HasRateDependence && ~obj.hasRateRows()
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

function out = generalProd(lhs, rhs)
    %GENERALPROD Align operands and multiply local Bernstein rows.
    if isa(lhs, "pdvar")
        anchor = lhs;
    elseif isa(rhs, "pdvar")
        anchor = rhs;
    else
        error("pdvar:InvalidMultiplication", "At least one operand must be a pdvar.");
    end

    % Align rate bounds, grids, and coefficient payloads before multiplication.
    rb = anchor.pickRateBounds("pdvar:InvalidMultiplication", lhs, rhs);
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

    sz = prodSz(ld.MatrixSize, rd.MatrixSize);
    % Multiply local rows while broadcasting ordinary rows as needed.
    plan = anchor.productPlan(ld.Degree, rd.Degree);
    vals = anchor.prodLocalValues(ld.LocalValues, ld.Degree, ...
        rd.LocalValues, rd.Degree, grid, ...
        "pdvar:InvalidMultiplication", plan, "fast");

    hasRate = ld.HasRateDependence || rd.HasRateDependence;
    if ~hasRate
        % Ordinary products do not retain rate bounds.
        rb = [];
    end
    out = pdvar(mkInit(grid, sz, ld.Degree + rd.Degree, vals, ...
        ld.ContainsDecision || rd.ContainsDecision, hasRate, rb, ...
        "expression", []));
end

function sz = prodSz(lhs, rhs)
    %PRODSZ Return scalar-aware matrix-product dimensions or fail explicitly.
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
