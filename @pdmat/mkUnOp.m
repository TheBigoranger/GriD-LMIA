function out = mkUnOp(obj, vals, sz)
    %MKUNOP Rebuild known coefficients and clear the stale FunctionHandle.
    %
    %   Syntax:
    %     out = obj.mkUnOp(vals, sz)
    %
    %   Arguments:
    %     vals - Mapped nested coefficient tree.
    %     sz   - New stored matrix payload size.
    %
    %   Output:
    %     out - Coefficient-backed pdmat with FunctionHandle cleared.
    %
    %   Example:
    %     out = obj.mkUnOp(vals, [1 1]);

    out = mkCoeffObj(obj.GridInfo.Vectors, vals, obj.Degree, ...
        obj.RateBounds, "coefficient-backed", [], sz, "fast", ...
        obj.NumRateRows);
end
