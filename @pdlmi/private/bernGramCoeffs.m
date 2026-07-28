function coeffs = bernGramCoeffs(gram, gramDegree, alphaPower, oneMinusAlphaPower, basisLabels)
    %BERNGRAMCOEFFS Map a weighted tensor Bernstein-Gram form to coefficients.
    %
    %   This compatibility entry point validates and builds one mapping plan.
    %   Repeated certificate assembly uses mkGramCertificatePlan and
    %   applyGramPlan so combinatorial work is not repeated per Gram block.

    if nargin < 5
        plan = mkGramPlan(gramDegree, alphaPower, oneMinusAlphaPower);
    else
        plan = mkGramPlan(gramDegree, alphaPower, ...
            oneMinusAlphaPower, basisLabels);
    end
    coeffs = applyGramPlan(gram, plan, true);
end
