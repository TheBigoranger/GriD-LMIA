function tbl = bernsteinTable(obj, varargin)
    %BERNSTEINTABLE Return a command-line Bernstein coefficient table for pdvar.
    %
    %   Syntax:
    %     T = bernsteinTable(P)
    %     T = bernsteinTable(P, cellSubs)
    %     T = bernsteinTable(P, "oneLine")
    %     T = bernsteinTable(P, cellSubs, "oneLine")
    %
    %   Arguments:
    %     P          - pdvar expression to inspect.
    %     cellSubs   - Optional physical-cell subscript row.
    %     "oneLine" - Optional expression-per-cell or rate-row mode.
    %
    %   Output:
    %     T - Table of cells, rate vertices, basis labels, and coefficients.
    %         Matrix coefficients use one table row per matrix row and show
    %         their shared metadata once on the centered display row.
    %
    %   Example:
    %     yalmip("clear");
    %     P = pdvar(1, {[0 1]});
    %     T = bernsteinTable(P, "oneLine");

    rateVerts = [];
    if obj.hasRateRows()
        % Expand RateBounds into the vertex rows consumed by pdbase.bernTbl.
        vecs = cell(1, size(obj.RateBounds, 1));
        for k = 1:size(obj.RateBounds, 1)
            vecs{k} = obj.RateBounds(k, :);
        end
        rateVerts = helper.combRows(vecs);
    end

    tbl = bernTbl(obj, "pdvar:InvalidBernsteinTableInput", ...
        @sdpText, @exprText, rateVerts, varargin{:});
end

function txt = exprText(val)
    %EXPRTEXT Group each complete coefficient before basis multiplication.
    txt = sdpText(val);
    if ~(startsWith(txt, "[") && endsWith(txt, "]"))
        txt = "[" + txt + "]";
    end
end

function txt = sdpText(val)
    %SDPTEXT Format numeric or symbolic coefficients as compact table text.
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
    % table remains scalar-row oriented like the numeric pdmat table.
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
