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
    %         A 1-by-1 pdmat acts as a scalar multiplier in either order.
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
        if lhs.NumRateRows ~= 0 || rhs.NumRateRows ~= 0
            % Even a proven-zero product must not bypass the exact-grid
            % contract attached to explicit rate-vertex coefficient tables.
            normOperand(grid, lhs, [], rb, "pdmat:InvalidMultiplication");
            normOperand(grid, rhs, [], rb, "pdmat:InvalidMultiplication");
        end
        out = zeroObj(grid, prodSz(lhs.MatrixSize, rhs.MatrixSize, ...
        "pdmat:InvalidMultiplication"));
        return
    end

    % Collapse numeric-zero products after validating their dimensions.
    if isa(lhs, "pdmat") && helper.isZero(rhs, "num")
        out = zeroObj(lhs.GridInfo.Vectors, prodSz(lhs.MatrixSize, size(rhs), ...
        "pdmat:InvalidMultiplication"));
        return
    end

    if helper.isZero(lhs, "num") && isa(rhs, "pdmat")
        out = zeroObj(rhs.GridInfo.Vectors, prodSz(size(lhs), rhs.MatrixSize, ...
        "pdmat:InvalidMultiplication"));
        return
    end

    % Preserve the grid while compacting an already-zero scalar product.
    if isa(lhs, "pdmat") && isnumeric(rhs) && isscalar(rhs) && ...
            isreal(rhs) && isfinite(rhs)

        if helper.isZero(lhs, "obj")
            out = zeroObj(lhs.GridInfo.Vectors, lhs.MatrixSize);
        else
            out = mapUnary(lhs, @(a) a * rhs);
        end

        return
    end

    if isnumeric(lhs) && isscalar(lhs) && isreal(lhs) && ...
            isfinite(lhs) && isa(rhs, "pdmat")

        if helper.isZero(rhs, "obj")
            out = zeroObj(rhs.GridInfo.Vectors, rhs.MatrixSize);
        else
            out = mapUnary(rhs, @(a) lhs * a);
        end

        return
    end

    % Align both operands on the common refinement grid before multiplication.
    rb = anchor.pickRateBounds("pdmat:InvalidMultiplication", lhs, rhs);
    grid = anchor.mergeGrid("pdmat:MixedGrid", lhs, rhs);
    ld = normOperand(grid, lhs, [], rb, "pdmat:InvalidMultiplication");
    rd = normOperand(grid, rhs, [], rb, "pdmat:InvalidMultiplication");

    % A 1-by-1 coefficient payload scales the other matrix; non-scalars
    % retain MATLAB's ordinary inner-dimension requirement.
    productSize = prodSz(ld.MatrixSize, rd.MatrixSize, ...
        "pdmat:InvalidMultiplication");

    % Multiply local Bernstein coefficients cell by cell.
    vals = anchor.prodVals(ld.LocalValues, ld.Degree, ...
        rd.LocalValues, rd.Degree, grid, ...
        "pdmat:InvalidMultiplication", "fast", ...
        ld.NumRateRows, rd.NumRateRows);

    % Compact products that cancel to an all-zero coefficient payload.
    if helper.isZero(vals, "vals")
        out = zeroObj(grid, productSize);
        return
    end

    out = mkCoeffObj(grid, vals, ld.Degree + rd.Degree, rb, [], [], [], ...
        "fast", max(ld.NumRateRows, rd.NumRateRows));
end

function sz = prodSz(lhs, rhs, errId)
    %PRODSZ Return scalar-aware product size after dimension validation.
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
