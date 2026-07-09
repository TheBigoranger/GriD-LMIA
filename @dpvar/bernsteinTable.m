function tbl = bernsteinTable(obj, varargin)
    %BERNSTEINTABLE Return a command-line Bernstein coefficient table for dpvar.
    %
    %   Syntax:
    %     T = bernsteinTable(P)
    %     T = bernsteinTable(P, cellSubs)
    %     T = bernsteinTable(P, "oneLine")
    %     T = bernsteinTable(P, cellSubs, "oneLine")
    %
    %   Example:
    %     yalmip("clear");
    %     P = dpvar(1, {[0 1]});
    %     T = bernsteinTable(P, "oneLine");

    nCoeff = (obj.Degree + 1) ^ obj.npar();
    rateVerts = [];
    if isRateRows(obj.LocalValues, obj.GridInfo.Vectors, nCoeff)
        % Expand RateBounds into the vertex rows consumed by helper.bernTbl.
        vecs = cell(1, size(obj.RateBounds, 1));
        for k = 1:size(obj.RateBounds, 1)
            vecs{k} = obj.RateBounds(k, :);
        end
        rateVerts = helper.combRows(vecs);
    end

    tbl = helper.bernTbl(obj, "dpvar:InvalidBernsteinTableInput", ...
        @sdpText, @sdpText, rateVerts, varargin{:});
end

function txt = sdpText(val)
    if ~isa(val, "sdpvar")
        txt = string(mat2str(val));
        return
    end

    if isscalar(val)
        txt = string(sdisplay(val));
        ids = depends(val);
        if numel(ids) == 1 && ...
                (any(txt == ["expr", "val"]) || ...
                any(startsWith(txt, ["expr(", "val("])))
            % Restore the stable YALMIP id when sdisplay collapses a pure variable.
            txt = "internal(" + string(ids) + ")";
        end
        return
    end

    % Keep matrix-valued coefficients as one compact display string so the
    % table remains scalar-row oriented like the numeric dpmat table.
    rows = strings(size(val, 1), 1);
    for r = 1:size(val, 1)
        cols = strings(1, size(val, 2));
        for c = 1:size(val, 2)
            expr = val(r, c);
            cols(c) = string(sdisplay(expr));
            ids = depends(expr);
            if numel(ids) == 1 && ...
                    (any(cols(c) == ["expr", "val"]) || ...
                    any(startsWith(cols(c), ["expr(", "val("])))
                cols(c) = "internal(" + string(ids) + ")";
            end
        end
        rows(r) = strjoin(cols, ", ");
    end
    txt = "[" + strjoin(rows, "; ") + "]";
end
