function cons = mkFullBoxCons(expr, relation, order)
    %MKFULLBOXCONS Define and assemble full-box-preordering constraints.
    %
    %   Syntax:
    %     cons = mkFullBoxCons(expr, relation, order)
    %
    %   Arguments:
    %     expr     - pdvar residual with local Bernstein coefficients.
    %     relation - Normalized "<=" or ">=" comparison relation.
    %     order    - Validated absolute full-box Gram order.
    %
    %   Output:
    %     cons - Cell column of YALMIP Gram and coefficient-matching constraints.
    %
    %   One parameter uses the parity-specific Markov-Lukacs specification.
    %   Multiple parameters use every subset mask of alpha_s(1-alpha_s), with
    %   all blocks passed to the shared cell/rate-row Gram assembler.

    nPar = numel(expr.GridInfo.Vectors);
    degree = expr.Degree;
    if nPar == 1 && mod(degree, 2) == 1
        targetDeg = 2 * order + 1;
        % Lower/left (1-alpha) precedes upper/right alpha.
        specs = {order, [0; 1]; order, [1; 0]};
    elseif nPar == 1
        targetDeg = 2 * order;
        specs = {order, [0; 0]};
        if order > 0
            specs(end + 1, :) = {order - 1, [1; 1]};
        end
    else
        targetDeg = 2 * order;
        masks = helper.combRows(repmat({0:1}, 1, nPar));
        specs = cell(size(masks, 1), 2);
        for k = 1:size(masks, 1)
            specs{k, 1} = order - masks(k, :);
            specs{k, 2} = [masks(k, :); masks(k, :)];
        end
    end

    cons = mkGramCons(expr, relation, targetDeg, specs);
end
