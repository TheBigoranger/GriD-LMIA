function cons = mkPutinarCons(expr, relation, order)
    %MKPUTINARCONS Define and assemble the Putinar quadratic-module blocks.
    %   The empty mask gives S0. Each singleton mask gives
    %   alpha_s(1-alpha_s)Ss; no generator products are included. Absolute
    %   order r uses basis degree r for S0, r-e_s for Ss, and matches the
    %   elevated target at tensor degree 2r.

    nPar = numel(expr.GridInfo.Vectors);
    masks = [zeros(1, nPar); eye(nPar)];
    specs = cell(size(masks, 1), 2);
    for k = 1:size(masks, 1)
        specs{k, 1} = order * ones(1, nPar) - masks(k, :);
        specs{k, 2} = [masks(k, :); masks(k, :)];
    end

    cons = mkGramCons(expr, relation, 2 * order, specs);
end
