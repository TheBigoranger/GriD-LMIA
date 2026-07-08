function out = unOp(obj, fcn)
    %UNOP Apply a unary coefficient operation to a coefficient-backed dpmat.

    if obj.SourceSummary == "function"
        error("dpmat:FunctionOnlyAlgebra", ...
            "Function-backed dpmat objects need explicit Bernstein coefficient evidence for this operation.");
    end
    vals = helper.mapVals(obj.LocalValues, fcn, obj.GridInfo.Vectors);
    out = dpmat(obj.GridInfo.Vectors, vals, Degree=obj.Degree);
end
