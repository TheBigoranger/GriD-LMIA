function tbl = bernsteinTable(obj, varargin)
    %BERNSTEINTABLE Return a command-line Bernstein coefficient table for pdmat.
    %
    %   Syntax:
    %     T = bernsteinTable(A)
    %     T = bernsteinTable(A, cellSubs)
    %     T = bernsteinTable(A, "oneLine")
    %     T = bernsteinTable(A, cellSubs, "oneLine")
    %
    %   Arguments:
    %     A          - Coefficient-backed pdmat object.
    %     cellSubs   - Optional physical-cell subscript row.
    %     "oneLine" - Optional expression-per-cell display mode.
    %
    %   Output:
    %     T - Table of cell, label, basis, and coefficient information.
    %         Matrix coefficients use one table row per matrix row and show
    %         their shared metadata once on the centered display row.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     T = bernsteinTable(A);
    %     T1 = bernsteinTable(A, 1, "oneLine");

    if obj.SourceSummary == "function"
        error("pdmat:FunctionOnlyBernsteinTable", ...
            "Function-only pdmat objects do not have Bernstein coefficient evidence to tabulate.");
    end

    rateVerts = [];
    if obj.hasRateRows()
        vecs = num2cell(obj.RateBounds, 2).';
        rateVerts = helper.combRows(vecs);
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
