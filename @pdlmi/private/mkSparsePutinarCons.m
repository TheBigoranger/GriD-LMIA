function cons = mkSparsePutinarCons(expr, relation, order, cliqueSize, comparisonMode, validationMode)
    %MKSPARSEPUTINARCONS Assemble tensor-window Putinar constraints.
    %
    %   Dense and sparse Putinar share the exact parity/mask convention.
    %   Sparse assembly changes only the Gram support: each Bernstein basis is
    %   covered by every axis-aligned label window with side
    %   min(cliqueSize, degree+1). The windows do not partition matrix entries.

    [targetDeg, specs] = mkPutinarSpec(expr, order);
    cons = mkGramCons(expr, relation, targetDeg, specs, ...
        comparisonMode, validationMode, cliqueSize);
end
