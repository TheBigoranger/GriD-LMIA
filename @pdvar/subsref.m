function varargout = subsref(obj, S)
    %SUBSREF Matrix block indexing for pdvar while preserving dot access.
    %
    %   Syntax:
    %     Q = P(rows, cols)
    %     c = P.coeffs(cellSubs)
    %
    %   Example:
    %     P = pdvar(2, 3, {[0 1]}, "full");
    %     q = P(:, 1);

    if strcmp(S(1).type, "()")
        [rows, cols] = pdbase.matSubs(S(1).subs, obj.MatrixSize, ...
            "pdvar:InvalidSubscript");
        vals = pdbase.mapVals(obj.LocalValues, @(a) a(rows, cols), ...
            obj.GridInfo.Vectors);
        out = pdvar(mkInit(obj.GridInfo.Vectors, [numel(rows), numel(cols)], ...
            obj.Degree, vals, obj.ContainsDecision, obj.HasRateDependence, ...
            obj.RateBounds, "expression", []));

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
        % numel(P) reports payload entries; property/method access still
        % returns one object-level value unless the property itself expands.
        out = cell(1, 1);
        out{1} = builtin("subsref", obj, S);
    end
end
