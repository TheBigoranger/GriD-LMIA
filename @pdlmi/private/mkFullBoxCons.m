function cons = mkFullBoxCons(expr, relation, order, comparisonMode, validationMode)
    %MKFULLBOXCONS Define and assemble full-box-preordering constraints.
    %
    %   Syntax:
    %     cons = mkFullBoxCons(expr, relation, order, mode)
    %
    %   Arguments:
    %     expr     - pdvar residual with local Bernstein coefficients.
    %     relation - Normalized "<=" or ">=" comparison relation.
    %     order    - Validated absolute full-box Gram order.
    %     mode     - Transient semidefinite or entry-wise assembly mode.
    %
    %   Output:
    %     cons - Cell column of YALMIP Gram and coefficient-matching constraints.
    %
    %   One parameter uses the parity-specific Markov-Lukacs specification.
    %   Multiple parameters use every subset mask of alpha_s(1-alpha_s), with
    %   all blocks passed to the shared cell/rate-row Gram assembler.

    [targetDeg, specs] = mkFullBoxSpec(expr, order);
    cons = mkGramCons(expr, relation, targetDeg, specs, ...
        comparisonMode, validationMode);
end
