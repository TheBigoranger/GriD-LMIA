function varargout = subsref(obj, S)
    %SUBSREF Matrix block indexing for pdmat while preserving dot access.
    %
    %   Syntax:
    %     B = A(rows, cols)
    %     c = A.coeffs(cellSubs)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);
    %     B = A(:, 1);

    if strcmp(S(1).type, "()")
        if obj.SourceSummary == "function"
            error("pdmat:FunctionOnlyAlgebra", ...
                "Function-backed pdmat objects need explicit Bernstein coefficient evidence for this operation.");
        end
        [rows, cols] = pdbase.matSubs(S(1).subs, obj.MatrixSize, ...
            "pdmat:InvalidSubscript");
        nCell = obj.GridInfo.NumNodes - 1;
        vals = helper.mkNest(nCell, @(subs) cellfun(@(a) a(rows, cols), ...
            helper.cellGet(obj.LocalValues, subs), UniformOutput=false));
        out = mkObj(obj.GridInfo.Vectors, vals, obj.Degree);

        if numel(S) == 1
            varargout{1} = out;
            return
        end
        varargout = dotRef(out, S(2:end), nargout);
        return
    end

    varargout = dotRef(obj, S, nargout);
end

function out = dotRef(obj, S, nOut)
    out = cell(1, max(nOut, 1));
    if nOut <= 1
        out{1} = builtin("subsref", obj, S);
        return
    end

    try
        [out{1:nOut}] = builtin("subsref", obj, S);
    catch err
        if err.identifier ~= "MATLAB:needMoreRhsOutputs"
            rethrow(err)
        end
        % numel(A) follows matrix-payload semantics, but scalar pdmat
        % property access still returns one value.
        out = cell(1, 1);
        out{1} = builtin("subsref", obj, S);
    end
end
