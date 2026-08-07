function obj = subsasgn(obj, S, rhs)
    %SUBSASGN In-bounds block replacement for pdvar expressions.
    %
    %   Syntax:
    %     P(rows, cols) = Q
    %     P(rows, cols) = M
    %
    %   Output:
    %     P - Updated pdvar expression with the selected matrix block replaced
    %         in every aligned coefficient.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "full");
    %     P(1, :) = [1 2];

    if ~strcmp(S(1).type, "()")
        obj = builtin("subsasgn", obj, S, rhs);
        return
    end
    if numel(S) ~= 1
        error("pdvar:UnsupportedAssignment", ...
            "pdvar only supports direct two-dimensional block assignment.");
    end
    if isnumeric(rhs) && isempty(rhs)
        error("pdvar:UnsupportedAssignment", ...
            "pdvar does not support deletion assignment.");
    end

    [rows, cols] = pdbase.matSubs(S(1).subs, obj.MatrixSize, ...
        "pdvar:InvalidAssignment");
    grid = obj.mergeGrid("pdvar:MixedGrid", rhs);
    rb = obj.pickRateBounds("pdvar:InvalidAssignment", rhs);
    lhsData = normOperand(grid, obj, [], rb, ...
        "pdvar:InvalidAssignment");
    rhsData = normOperand(grid, rhs, [numel(rows), numel(cols)], ...
        rb, "pdvar:InvalidAssignment");

    deg = max(lhsData.Degree, rhsData.Degree);
    data = pdbase.elevData([lhsData, rhsData], deg, grid, "fast");
    lhsVals = data(1).LocalValues;
    rhsVals = data(2).LocalValues;
    vals = obj.zipRateRows(lhsVals, rhsVals, ...
        @(lhs, rhs) setBlock(lhs, rhs, rows, cols), grid, ...
        "pdvar:InvalidCoefficientRows");

    hasDec = lhsData.ContainsDecision || rhsData.ContainsDecision;
    numRateRows = max(lhsData.NumRateRows, rhsData.NumRateRows);
    obj = pdvar(mkCtorState(grid, obj.MatrixSize, deg, vals, hasDec, rb, ...
        "expression", [], "fast", numRateRows));
end

function out = setBlock(lhs, rhs, rows, cols)
    out = lhs;
    out(rows, cols) = rhs;
end
