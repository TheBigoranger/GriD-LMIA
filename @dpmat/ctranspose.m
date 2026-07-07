function out = ctranspose(obj)
    %CTRANSPOSE Conjugate-transpose each coefficient payload of a dpmat.
    %
    %   Syntax:
    %     B = A'
    %
    %   Example:
    %     A = dpmat({[0 1]}, {[1 2], [3 4]}, Degree=1);
    %     B = A';

    if obj.SourceSummary == "function"
        error("dpmat:FunctionOnlyAlgebra", ...
            "Function-backed dpmat objects need explicit Bernstein coefficient evidence for this operation.");
    end
    nCell = obj.GridInfo.NumNodes - 1;
    vals = internal.mkNest(nCell, @(subs) cellfun(@(a) a', ...
        internal.cellGet(obj.LocalValues, subs), UniformOutput=false));
    out = dpmat(obj.GridInfo.Vectors, vals, Degree=obj.Degree);
end
