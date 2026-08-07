function out = mkRhodiff(obj, deg, vals, rb, hasDec, numRateRows)
    %MKRHODIFF Rebuild a derivative while preserving pdvar value semantics.
    %
    %   Syntax:
    %     out = obj.mkRhodiff(deg, vals, rb, hasDec, numRateRows)
    %
    %   Arguments:
    %     deg    - Degree of the derivative coefficient tree.
    %     vals   - Nested derivative coefficient tree with rate rows.
    %     rb     - RateBounds used to enumerate derivative-rate vertices.
    %     hasDec - Whether derivative payloads contain YALMIP decisions.
    %     numRateRows - Number of distinct derivative-rate vertices.
    %
    %   Output:
    %     out - Discontinuous derivative pdvar expression.
    %
    %   Example:
    %     out = obj.mkRhodiff(deg, vals, obj.RateBounds, true, ...
    %         numRateRows);

    out = pdvar(mkCtorState(obj.GridInfo.Vectors, obj.MatrixSize, deg, vals, ...
        hasDec, rb, "derivative", false, "fast", numRateRows));
end
