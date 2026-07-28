function out = mtimes(lhs, rhs)
    %MTIMES Matrix product for coefficient-backed pdmat operands.
    %
    %   Syntax:
    %     C = A * B
    %     C = A * M
    %     C = M * A
    %
    %   Arguments:
    %     lhs, rhs - Compatible coefficient-backed pdmat or numeric operands.
    %
    %   Output:
    %     C - Cell-local Bernstein matrix product on the common grid.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 0; 0 1], [2 0; 0 2]}, Degree=1);
    %     B = pdmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    %     C = A * B;

    if isa(lhs, "pdmat")
        anchor = lhs;
    else
        anchor = rhs;
    end

    % Validate grid and size before collapsing a zero-object product.
    if isa(lhs, "pdmat") && isa(rhs, "pdmat") && ...
            (helper.isZero(lhs, "obj") || helper.isZero(rhs, "obj"))
        rb = lhs.pickRateBounds("pdmat:InvalidMultiplication", lhs, rhs);
        grid = lhs.mergeGrid("pdmat:MixedGrid", lhs, rhs);
        if lhs.hasRateRows() || rhs.hasRateRows()
            % Even a proven-zero product must not bypass the exact-grid
            % contract attached to explicit rate-vertex coefficient tables.
            asData(grid, lhs, [], rb, "pdmat:InvalidMultiplication");
            asData(grid, rhs, [], rb, "pdmat:InvalidMultiplication");
        end
        out = zeroObj(grid, zeroProdSz(lhs.MatrixSize, rhs.MatrixSize, ...
        "pdmat:InvalidMultiplication"));
        return
    end

    % Collapse numeric-zero products after validating their dimensions.
    if isa(lhs, "pdmat") && helper.isZero(rhs, "num")
        out = zeroObj(lhs.GridInfo.Vectors, zeroProdSz(lhs.MatrixSize, size(rhs), ...
        "pdmat:InvalidMultiplication"));
        return
    end

    if helper.isZero(lhs, "num") && isa(rhs, "pdmat")
        out = zeroObj(rhs.GridInfo.Vectors, zeroProdSz(size(lhs), rhs.MatrixSize, ...
        "pdmat:InvalidMultiplication"));
        return
    end

    % Preserve the grid while compacting an already-zero scalar product.
    if isa(lhs, "pdmat") && isnumeric(rhs) && isscalar(rhs) && ...
            isreal(rhs) && isfinite(rhs)

        if helper.isZero(lhs, "obj")
            out = zeroObj(lhs.GridInfo.Vectors, lhs.MatrixSize);
        else
            out = unOp(lhs, @(a) a * rhs);
        end

        return
    end

    if isnumeric(lhs) && isscalar(lhs) && isreal(lhs) && ...
            isfinite(lhs) && isa(rhs, "pdmat")

        if helper.isZero(rhs, "obj")
            out = zeroObj(rhs.GridInfo.Vectors, rhs.MatrixSize);
        else
            out = unOp(rhs, @(a) lhs * a);
        end

        return
    end

    % Align both operands on the common refinement grid before multiplication.
    rb = anchor.pickRateBounds("pdmat:InvalidMultiplication", lhs, rhs);
    grid = anchor.mergeGrid("pdmat:MixedGrid", lhs, rhs);
    ld = asData(grid, lhs, [], rb, "pdmat:InvalidMultiplication");
    rd = asData(grid, rhs, [], rb, "pdmat:InvalidMultiplication");

    % Validate inner dimensions after numeric operands have been promoted.
    if ld.MatrixSize(2) ~= rd.MatrixSize(1)
        error("pdmat:InvalidMultiplication", ...
        "Inner matrix dimensions must agree for pdmat multiplication.");
    end

    % Multiply local Bernstein coefficients cell by cell.
    plan = anchor.productPlan(ld.Degree, rd.Degree);
    vals = anchor.prodLocalValues(ld.LocalValues, ld.Degree, ...
        rd.LocalValues, rd.Degree, grid, ...
        "pdmat:InvalidMultiplication", plan, "fast");

    % Compact products that cancel to an all-zero coefficient payload.
    if helper.isZero(vals, "vals")
        out = zeroObj(grid, zeroProdSz(ld.MatrixSize, rd.MatrixSize, ...
        "pdmat:InvalidMultiplication"));
        return
    end

    hasRate = ld.HasRateDependence || rd.HasRateDependence;
    if ~hasRate
        rb = [];
    end
    out = mkObj(grid, vals, ld.Degree + rd.Degree, rb);
end

function sz = zeroProdSz(lhs, rhs, errId)
    %ZEROPRODSZ Return scalar-aware product size after dimension validation.
    lhsScalar = isequal(lhs, [1 1]);
    rhsScalar = isequal(rhs, [1 1]);

    % A 1-by-1 operand acts as a scalar multiplier.
    if lhsScalar
        sz = rhs;
        return
    end

    if rhsScalar
        sz = lhs;
        return
    end

    % Non-scalar products use the ordinary [m-by-k] * [k-by-n] contract.
    if lhs(2) ~= rhs(1)
        error(errId, "Inner matrix dimensions must agree for pdmat multiplication.");
    end

    sz = [lhs(1), rhs(2)];
end
