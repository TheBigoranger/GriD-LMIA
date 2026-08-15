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
    %         A 1-by-1 pdvar or pdmat acts as a scalar multiplier.
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
            out = genProd(lhs, rhs);
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
            if lhs.NumRateRows ~= 0 || rhs.NumRateRows ~= 0
                normOperand(grid, lhs, [], rb, "pdvar:InvalidMultiplication");
                normOperand(grid, rhs, [], rb, "pdvar:InvalidMultiplication");
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
            if lhs.NumRateRows ~= 0 || rhs.NumRateRows ~= 0
                normOperand(grid, lhs, [], rb, "pdvar:InvalidMultiplication");
                normOperand(grid, rhs, [], rb, "pdvar:InvalidMultiplication");
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

    if helper.isZero(obj, "obj")
        out = zeroObj(obj.GridInfo.Vectors, obj.MatrixSize);
    elseif leftScale
        out = mapUnary(obj, @(a) scale * a);
    else
        out = mapUnary(obj, @(a) a * scale);
    end
end

function out = genProd(lhs, rhs)
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
    ld = normOperand(grid, lhs, [], rb, "pdvar:InvalidMultiplication");
    rd = normOperand(grid, rhs, [], rb, "pdvar:InvalidMultiplication");

    % Keep the product inside the affine decision layer.
    if ld.ContainsDecision && rd.ContainsDecision
        error("pdvar:InvalidMultiplication", ...
            "Products may contain decision variables on at most one side.");
    end
    % RateBounds alone is metadata; only stored vertex rows make a factor
    % rate-dependent. Two active row tables would be quadratic in rho_dot.
    if ld.NumRateRows ~= 0 && rd.NumRateRows ~= 0
        error("pdvar:InvalidMultiplication", ...
            "Products may contain derivative rate vertices on at most one side.");
    end

    sz = prodSz(ld.MatrixSize, rd.MatrixSize);
    % Multiply local rows while broadcasting ordinary rows as needed.
    vals = anchor.prodVals(ld.LocalValues, ld.Degree, ...
        rd.LocalValues, rd.Degree, grid, ...
        "pdvar:InvalidMultiplication", "fast", ...
        ld.NumRateRows, rd.NumRateRows);

    out = pdvar(mkCtorState(grid, sz, ld.Degree + rd.Degree, vals, ...
        ld.ContainsDecision || rd.ContainsDecision, rb, ...
        "expression", [], "fast", max(ld.NumRateRows, rd.NumRateRows)));
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
