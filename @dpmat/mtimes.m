function out = mtimes(lhs, rhs)
    %MTIMES Matrix product for coefficient-backed dpmat operands.
    %
    %   Syntax:
    %     C = A * B
    %     C = A * M
    %     C = M * A
    %
    %   Example:
    %     A = dpmat({[0 1]}, {[1 0; 0 1], [2 0; 0 2]}, Degree=1);
    %     B = dpmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    %     C = A * B;

    if isa(lhs, "dpmat")
        anchor = lhs;
    else
        anchor = rhs;
    end

    % Validate grid and size before collapsing a zero-object product.
    if isa(lhs, "dpmat") && isa(rhs, "dpmat") && ...
            (helper.isZero(lhs, "obj") || helper.isZero(rhs, "obj"))
        grid = lhs.mergeGrid("dpmat:MixedGrid", lhs, rhs);
        out = zeroObj(grid, zeroProdSize(lhs.MatrixSize, rhs.MatrixSize, ...
        "dpmat:InvalidMultiplication"));
        return
    end

    % Collapse numeric-zero products after validating their dimensions.
    if isa(lhs, "dpmat") && helper.isZero(rhs, "num")
        out = zeroObj(lhs.GridInfo.Vectors, zeroProdSize(lhs.MatrixSize, size(rhs), ...
        "dpmat:InvalidMultiplication"));
        return
    end

    if helper.isZero(lhs, "num") && isa(rhs, "dpmat")
        out = zeroObj(rhs.GridInfo.Vectors, zeroProdSize(size(lhs), rhs.MatrixSize, ...
        "dpmat:InvalidMultiplication"));
        return
    end

    % Preserve the grid while compacting an already-zero scalar product.
    if isa(lhs, "dpmat") && isnumeric(rhs) && isscalar(rhs) && ...
            isreal(rhs) && isfinite(rhs)

        if helper.isZero(lhs, "obj")
            out = zeroObj(lhs.GridInfo.Vectors, lhs.MatrixSize);
        else
            out = unOp(lhs, @(a) a * rhs);
        end

        return
    end

    if isnumeric(lhs) && isscalar(lhs) && isreal(lhs) && ...
            isfinite(lhs) && isa(rhs, "dpmat")

        if helper.isZero(rhs, "obj")
            out = zeroObj(rhs.GridInfo.Vectors, rhs.MatrixSize);
        else
            out = unOp(rhs, @(a) lhs * a);
        end

        return
    end

    % Align both operands on the common refinement grid before multiplication.
    grid = anchor.mergeGrid("dpmat:MixedGrid", lhs, rhs);
    ld = asData(grid, lhs, [], "dpmat:InvalidMultiplication");
    rd = asData(grid, rhs, [], "dpmat:InvalidMultiplication");

    % Validate inner dimensions after numeric operands have been promoted.
    if ld.MatrixSize(2) ~= rd.MatrixSize(1)
        error("dpmat:InvalidMultiplication", ...
        "Inner matrix dimensions must agree for dpmat multiplication.");
    end

    % Multiply local Bernstein coefficients cell by cell.
    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) anchor.bernProd( ...
        helper.cellGet(ld.LocalValues, subs), ld.Degree, ...
        helper.cellGet(rd.LocalValues, subs), rd.Degree));

    % Compact products that cancel to an all-zero coefficient payload.
    if helper.isZero(vals, "vals")
        out = zeroObj(grid, zeroProdSize(ld.MatrixSize, rd.MatrixSize, ...
        "dpmat:InvalidMultiplication"));
        return
    end

    out = mkObj(grid, vals, ld.Degree + rd.Degree);
end

function sz = zeroProdSize(lhs, rhs, errId)
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
        error(errId, "Inner matrix dimensions must agree for dpmat multiplication.");
    end

    sz = [lhs(1), rhs(2)];
end
