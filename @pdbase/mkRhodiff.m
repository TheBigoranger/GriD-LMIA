function out = mkRhodiff(obj, deg, vals, rb, hasDec, numRateRows, continuity)
    %MKRHODIFF Rebuild a base-class derivative result.
    %
    %   Syntax:
    %     out = obj.mkRhodiff(deg, vals, rb, hasDec, numRateRows, continuity)
    %
    %   Arguments:
    %     deg    - Degree of the derivative coefficient tree.
    %     vals   - Nested derivative coefficient tree with rate rows.
    %     rb     - RateBounds used to enumerate derivative-rate vertices.
    %     hasDec - Whether derivative payloads contain YALMIP decisions.
    %     numRateRows - Number of distinct derivative-rate vertices.
    %     continuity - Proven direction-wise lower bound after differentiation.
    %
    %   Output:
    %     out - Rate-dependent pdbase derivative with the supplied bound.
    %
    %   Example:
    %     out = obj.mkRhodiff(deg, vals, obj.RateBounds, ...
    %         obj.ContainsDecision, numRateRows, continuity);
    %
    %   Derived classes override this hook so shared rhodiff traversal can
    %   rebuild pdmat or pdvar without knowing constructor-private state.

    out = pdbase(obj.GridInfo.Vectors, obj.MatrixSize, deg, vals, ...
        Continuity=continuity, ContainsDecision=hasDec, ...
        NumRateRows=numRateRows, RateBounds=rb, ...
        SourceSummary="derivative");
end
