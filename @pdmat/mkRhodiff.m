function out = mkRhodiff(obj, deg, vals, rb, ~)
    %MKRHODIFF Rebuild a numeric derivative and clear exact-function state.

    init = struct;
    init.PdmatInternal = true;
    init.Grid = obj.GridInfo.Vectors;
    init.MatrixSize = obj.MatrixSize;
    init.Degree = deg;
    init.LocalValues = vals;
    init.IsContinuous = false;
    init.ContainsDecision = false;
    init.HasRateDependence = true;
    init.RateBounds = rb;
    init.SourceSummary = "derivative";
    init.FunctionHandle = [];
    out = pdmat(init);
end
