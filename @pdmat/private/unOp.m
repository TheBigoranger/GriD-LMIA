function out = unOp(obj, fcn)
    %UNOP Apply a unary coefficient operation to a coefficient-backed pdmat.
    %
    %   Syntax:
    %     out = unOp(obj, fcn)
    %
    %   Example (via public algebra):
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     B = -A;
    %
    %   Function-only pdmat objects are rejected because their inherited
    %   placeholder coefficients are not evidence for coefficient algebra.

    if obj.SourceSummary == "function"
        error("pdmat:FunctionOnlyAlgebra", ...
            "Function-backed pdmat objects need explicit Bernstein coefficient evidence for this operation.");
    end
    vals = helper.mapVals(obj.LocalValues, fcn, obj.GridInfo.Vectors);
    out = mkObj(obj.GridInfo.Vectors, vals, obj.Degree);
end
