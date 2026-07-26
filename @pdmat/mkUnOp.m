function out = mkUnOp(obj, vals, ~)
    %MKUNOP Rebuild known coefficients and clear the stale FunctionHandle.

    out = mkObj(obj.GridInfo.Vectors, vals, obj.Degree);
end
