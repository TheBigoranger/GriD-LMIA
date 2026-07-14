function out = ctranspose(obj)
    %CTRANSPOSE Conjugate-transpose each coefficient payload of a pdmat.
    %
    %   Syntax:
    %     B = A'
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2], [3 4]}, Degree=1);
    %     B = A';

    if obj.SourceSummary == "function"
        error("pdmat:FunctionOnlyAlgebra", ...
            "Function-backed pdmat objects need explicit Bernstein coefficient evidence for this operation.");
    end
    nCell = obj.GridInfo.NumNodes - 1;
    vals = helper.mkNest(nCell, @(subs) cellfun(@(a) a', ...
        helper.cellGet(obj.LocalValues, subs), UniformOutput=false));
    out = mkObj(obj.GridInfo.Vectors, vals, obj.Degree);
end
