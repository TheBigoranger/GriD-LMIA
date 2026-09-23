function out = mkRhodiff(obj, deg, vals, rb, ~, numRateRows, continuity)
    %MKRHODIFF Rebuild a numeric derivative and clear exact-function state.
    %
    %   Syntax:
    %     out = obj.mkRhodiff(deg, vals, rb, hasDec, numRateRows, continuity)
    %
    %   Arguments:
    %     deg  - Degree of the derivative coefficient tree.
    %     vals - Nested derivative coefficient tree with rate rows.
    %     rb   - RateBounds used to enumerate derivative-rate vertices.
    %     numRateRows - Number of distinct derivative-rate vertices.
    %     continuity - Proven direction-wise lower bound after differentiation.
    %
    %   Output:
    %     out - Derivative pdmat with no FunctionHandle and the supplied bound.
    %
    %   Example:
    %     out = obj.mkRhodiff(deg, vals, obj.RateBounds, false, ...
    %         numRateRows, continuity);

    init = struct;
    init.PdmatInternal = true;
    init.Grid = obj.GridInfo.Vectors;
    init.MatrixSize = obj.MatrixSize;
    init.Degree = deg;
    init.LocalValues = vals;
    init.Continuity = continuity;
    init.ContainsDecision = false;
    init.NumRateRows = numRateRows;
    init.RateBounds = rb;
    init.SourceSummary = "derivative";
    init.FunctionHandle = [];
    out = pdmat(init);
end
