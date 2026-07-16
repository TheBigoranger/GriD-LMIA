function cons = mkPutinarCons(expr, relation, order)
    %MKPUTINARCONS Define and assemble Putinar quadratic-module constraints.
    %
    %   Syntax:
    %     cons = mkPutinarCons(expr, relation, order)
    %
    %   Arguments:
    %     expr     - pdvar residual with local Bernstein coefficients.
    %     relation - Normalized "<=" or ">=" comparison relation.
    %     order    - Validated absolute Putinar Gram order.
    %
    %   Output:
    %     cons - Cell column of YALMIP Gram and coefficient-matching constraints.
    %
    %   In one parameter, reuse the exact Markov-Lukacs parity specification
    %   from the full-box assembler. Otherwise, the empty mask gives S0 and
    %   each singleton mask gives alpha_s(1-alpha_s)Ss; no generator products
    %   are included. Absolute order r uses basis degree r for S0, r-e_s for
    %   Ss, and matches the elevated target at tensor degree 2r.

    nPar = numel(expr.GridInfo.Vectors);
    if nPar == 1
        cons = mkFullBoxCons(expr, relation, order);
        return
    end

    masks = [zeros(1, nPar); eye(nPar)];
    specs = cell(size(masks, 1), 2);
    for k = 1:size(masks, 1)
        specs{k, 1} = order * ones(1, nPar) - masks(k, :);
        specs{k, 2} = [masks(k, :); masks(k, :)];
    end

    cons = mkGramCons(expr, relation, 2 * order, specs);
end
