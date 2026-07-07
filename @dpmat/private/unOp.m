function out = unOp(obj, fcn)
    %UNOP Apply a unary coefficient operation to a coefficient-backed dpmat.

    if obj.SourceSummary == "function"
        error("dpmat:FunctionOnlyAlgebra", ...
            "Function-backed dpmat objects need explicit Bernstein coefficient evidence for this operation.");
    end
    nCell = obj.GridInfo.NumNodes - 1;
    vals = internal.mkNest(nCell, @(subs) cellfun(fcn, ...
        internal.cellGet(obj.LocalValues, subs), UniformOutput=false));
    out = dpmat(obj.GridInfo.Vectors, vals, Degree=obj.Degree);
end
