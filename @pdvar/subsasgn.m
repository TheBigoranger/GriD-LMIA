function obj = subsasgn(obj, S, rhs)
    %SUBSASGN In-bounds block replacement for pdvar expressions.
    %
    %   Syntax:
    %     P(rows, cols) = Q
    %     P(rows, cols) = M
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
    rb = pickRb("pdvar:InvalidAssignment", obj, rhs);
    lhsData = asData(grid, obj, [], rb, ...
        "pdvar:InvalidAssignment");
    rhsData = asData(grid, rhs, [numel(rows), numel(cols)], ...
        rb, "pdvar:InvalidAssignment");

    deg = max(lhsData.Degree, rhsData.Degree);
    lhsVals = pdbase.elevLocalValues(lhsData.LocalValues, lhsData.Degree, deg, grid);
    rhsVals = pdbase.elevLocalValues(rhsData.LocalValues, rhsData.Degree, deg, grid);
    vals = zipRows(lhsVals, rhsVals, @(lhs, rhs) assignBlock(lhs, rhs, rows, cols), grid);

    hasDec = lhsData.ContainsDecision || rhsData.ContainsDecision;
    hasRate = lhsData.HasRateDependence || rhsData.HasRateDependence;
    if ~hasRate
        rb = [];
    end
    obj = pdvar(mkInit(grid, obj.MatrixSize, deg, vals, hasDec, hasRate, rb, ...
        "expression", lhsData.IsContinuous && rhsData.IsContinuous));
end

function out = assignBlock(lhs, rhs, rows, cols)
    out = lhs;
    out(rows, cols) = rhs;
end
