function out = unOp(obj, fcn)
    %UNOP Apply a unary coefficient operation to a coefficient-backed dpmat.
    %
    %   Syntax:
    %     out = unOp(obj, fcn)
    %
    %   Example (via public algebra):
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     B = -A;
    %
    %   Function-only dpmat objects are rejected because their inherited
    %   placeholder coefficients are not evidence for coefficient algebra.

    if obj.SourceSummary == "function"
        error("dpmat:FunctionOnlyAlgebra", ...
            "Function-backed dpmat objects need explicit Bernstein coefficient evidence for this operation.");
    end
    vals = helper.mapVals(obj.LocalValues, fcn, obj.GridInfo.Vectors);
    out = dpmat(obj.GridInfo.Vectors, vals, Degree=obj.Degree);
end
