function varargout = subsref(obj, S)
    %SUBSREF Matrix block indexing for dpmat while preserving dot access.
    %
    %   Syntax:
    %     B = A(rows, cols)
    %     c = A.coeffs(cellSubs)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);
    %     B = A(:, 1);

    if strcmp(S(1).type, "()")
        if obj.SourceSummary == "function"
            error("dpmat:FunctionOnlyAlgebra", ...
                "Function-backed dpmat objects need explicit Bernstein coefficient evidence for this operation.");
        end
        [rows, cols] = matSubs(S(1).subs, obj.MatrixSize, "dpmat:InvalidSubscript");
        nCell = obj.GridInfo.NumNodes - 1;
        vals = internal.mkNest(nCell, @(subs) cellfun(@(a) a(rows, cols), ...
            internal.cellGet(obj.LocalValues, subs), UniformOutput=false));
        out = dpmat(obj.GridInfo.Vectors, vals, Degree=obj.Degree);

        if numel(S) == 1
            varargout{1} = out;
            return
        end
        [varargout{1:nargout}] = builtin("subsref", out, S(2:end));
        return
    end

    [varargout{1:nargout}] = builtin("subsref", obj, S);
end
