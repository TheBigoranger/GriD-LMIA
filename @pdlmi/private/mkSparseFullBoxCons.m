function cons = mkSparseFullBoxCons(expr, relation, order, bandWidth, mode)
    %MKSPARSEFULLBOXCONS Assemble tensor-window full-box constraints.
    %
    %   The dense and sparse families share the exact parity/mask convention.
    %   Sparse assembly changes only the Gram support: each dense basis is covered
    %   by every axis-aligned window with side min(bandWidth, degree+1).

    [targetDeg, specs] = mkFullBoxSpec(expr, order);
    cons = mkGramCons(expr, relation, targetDeg, specs, mode, bandWidth);
end
