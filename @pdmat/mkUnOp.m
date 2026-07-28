function out = mkUnOp(obj, vals, sz)
    %MKUNOP Rebuild known coefficients and clear the stale FunctionHandle.

    out = mkObj(obj.GridInfo.Vectors, vals, obj.Degree, ...
        obj.RateBounds, "coefficient-backed", [], sz);
end
