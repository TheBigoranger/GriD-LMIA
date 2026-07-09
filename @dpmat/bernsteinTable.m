function tbl = bernsteinTable(obj, varargin)
    %BERNSTEINTABLE Return a command-line Bernstein coefficient table for dpmat.
    %
    %   Syntax:
    %     T = bernsteinTable(A)
    %     T = bernsteinTable(A, cellSubs)
    %     T = bernsteinTable(A, "oneLine")
    %     T = bernsteinTable(A, cellSubs, "oneLine")
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     T = bernsteinTable(A);
    %     T1 = bernsteinTable(A, 1, "oneLine");

    if obj.SourceSummary == "function"
        error("dpmat:FunctionOnlyBernsteinTable", ...
            "Function-only dpmat objects do not have Bernstein coefficient evidence to tabulate.");
    end

    tbl = helper.bernTbl(obj, "dpmat:InvalidBernsteinTableInput", ...
        @(val) val, @(val) string(mat2str(val)), [], varargin{:});
end
