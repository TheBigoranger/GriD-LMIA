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
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     T = bernsteinTable(A);
    %     T1 = bernsteinTable(A, 1, "oneLine");

    if obj.SourceSummary == "function"
        error("pdmat:FunctionOnlyBernsteinTable", ...
            "Function-only pdmat objects do not have Bernstein coefficient evidence to tabulate.");
    end

    tbl = helper.bernTbl(obj, "pdmat:InvalidBernsteinTableInput", ...
        @(val) val, @(val) string(mat2str(val)), [], varargin{:});
end
