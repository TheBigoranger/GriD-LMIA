function out = mkRhodiff(obj, deg, vals, rb, hasDec, numRateRows, continuity)
    %MKRHODIFF Rebuild a derivative while preserving pdvar value semantics.
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
    %     out - Derivative pdvar expression with the supplied lower bound.
    %
    %   Example:
    %     out = obj.mkRhodiff(deg, vals, obj.RateBounds, true, ...
    %         numRateRows, continuity);

    out = pdvar(mkCtorState(obj.GridInfo.Vectors, obj.MatrixSize, deg, vals, ...
        hasDec, rb, "derivative", continuity, "fast", numRateRows));
end
