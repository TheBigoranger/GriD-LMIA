function cons = mkPutinarCons(expr, relation, order, comparisonMode, validationMode)
    %MKPUTINARCONS Define and assemble Putinar quadratic-module constraints.
    %
    %   Syntax:
    %     cons = mkPutinarCons(expr, relation, order, mode)
    %
    %   Arguments:
    %     expr     - pdvar residual with local Bernstein coefficients.
    %     relation - Normalized "<=" or ">=" comparison relation.
    %     order    - Validated absolute Putinar Gram order.
    %     mode     - Transient semidefinite or entry-wise assembly mode.
    %
    %   Output:
    %     cons - Cell column of YALMIP Gram and coefficient-matching constraints.
    %
    %   In one parameter, reuse the exact Markov-Lukacs parity specification
    %   from the full-box assembler. Otherwise, the empty mask gives S0 and
    %   each singleton mask gives alpha_s(1-alpha_s)Ss; no generator products
    %   are included. Absolute order r uses basis degree r for S0, r-e_s for
    %   Ss, and matches the elevated target at tensor degree 2r.

    [targetDeg, specs] = mkPutinarSpec(expr, order);
    cons = mkGramCons(expr, relation, targetDeg, specs, ...
        comparisonMode, validationMode);
end
