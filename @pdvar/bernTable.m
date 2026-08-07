function tbl = bernTable(obj, varargin)
    %BERNTABLE Return a command-line Bernstein coefficient table for pdvar.
    %
    %   Syntax:
    %   tbl = obj.bernTable() lists every physical cell.
    %   tbl = obj.bernTable(cellSubs) selects one cell.
    %   tbl = obj.bernTable(..., "oneLine") combines each symbolic coefficient
    %   with its Bernstein basis text. The output is a MATLAB table in
    %   repository coefficient and rate-vertex order. Invalid cell subscripts,
    %   repeated selectors, and unknown text options are rejected.
    %
    %   Output:
    %     tbl - MATLAB table with symbolic coefficient text and Bernstein
    %           basis metadata.
    %
    %   Example:
    %     P = pdvar(1, [0 1], Degree=2);
    %     tbl = P.bernTable("oneLine");

    rateVerts = [];
    if obj.NumRateRows ~= 0
        rateVerts = helper.rateVerts(obj.RateBounds);
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
        txt = oneText(val);
        return
    end
    rows = strings(size(val, 1), 1);
    for r = 1:size(val, 1)
        cols = strings(1, size(val, 2));
        for c = 1:size(val, 2)
            cols(c) = oneText(val(r, c));
        end
        rows(r) = strjoin(cols, ", ");
    end
    txt = "[" + strjoin(rows, "; ") + "]";
end

function txt = oneText(val)
    %ONETEXT Restore stable YALMIP ids when sdisplay hides pure variables.
    txt = string(sdisplay(val));
    ids = depends(val);
    if numel(ids) == 1 && (any(txt == ["expr", "val"]) || ...
            any(startsWith(txt, ["expr(", "val("])))
        txt = "internal(" + string(ids) + ")";
    end
end
