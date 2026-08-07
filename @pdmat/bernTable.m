function tbl = bernTable(obj, varargin)
    %BERNTABLE Return a command-line Bernstein coefficient table for pdmat.
    %
    %   Syntax:
    %     tbl = obj.bernTable()
    %     tbl = obj.bernTable(cellSubs)
    %     tbl = obj.bernTable(..., "oneLine")
    %
    %   Output:
    %     tbl - MATLAB table in repository coefficient and rate-vertex order.
    %
    %   The "oneLine" option combines each coefficient with its Bernstein
    %   basis text. Function-only objects, invalid cell subscripts, repeated
    %   selectors, and unknown text options are rejected.
    %
    %   Output:
    %     tbl - MATLAB table in repository coefficient and rate-vertex order.
    %
    %   Output:
    %     tbl - MATLAB table in repository coefficient and rate-vertex order.
    %
    %   Example:
    %     A = pdmat([0 1], {1, 3}, Degree=1);
    %     tbl = A.bernTable("oneLine");

    if obj.SourceSummary == "function"
        error("pdmat:FunctionOnlyBernsteinTable", ...
            "Function-only pdmat objects do not have Bernstein coefficient evidence to tabulate.");
    end
    rateVerts = [];
    if obj.NumRateRows ~= 0
        rateVerts = helper.rateVerts(obj.RateBounds);
    end
    tbl = bernTbl(obj, "pdmat:InvalidBernsteinTableInput", ...
        @(val) val, @exprText, rateVerts, varargin{:});
end

function txt = exprText(val)
    %EXPRTEXT Match the active MATLAB numeric format without padded columns.
    txt = strip(string(formattedDisplayText( ...
        val, "SuppressMarkup", true)));
    txt = regexprep(txt, "\s+", " ");
    if ~isscalar(val)
        txt = "[" + txt + "]";
    end
end
