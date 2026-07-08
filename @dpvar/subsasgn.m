function obj = subsasgn(obj, S, rhs)
    %SUBSASGN In-bounds block replacement for dpvar expressions.
    %
    %   Syntax:
    %     P(rows, cols) = Q
    %     P(rows, cols) = M
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "full");
    %     P(1, :) = [1 2];

    if ~strcmp(S(1).type, "()")
        obj = builtin("subsasgn", obj, S, rhs);
        return
    end
    if numel(S) ~= 1
        error("dpvar:UnsupportedAssignment", ...
            "dpvar only supports direct two-dimensional block assignment.");
    end
    if isnumeric(rhs) && isempty(rhs)
        error("dpvar:UnsupportedAssignment", ...
            "dpvar does not support deletion assignment.");
    end

    [rows, cols] = helper.matSubs(S(1).subs, obj.MatrixSize, ...
        "dpvar:InvalidAssignment");
    grid = obj.mergeGrid("dpvar:MixedGrid", rhs);
    rb = pickRb("dpvar:InvalidAssignment", obj, rhs);
    lhsData = asData(grid, obj, [], rb, ...
        "dpvar:InvalidAssignment");
    rhsData = asData(grid, rhs, [numel(rows), numel(cols)], ...
        rb, "dpvar:InvalidAssignment");

    deg = max(lhsData.Degree, rhsData.Degree);
    lhsVals = elevVals(obj, lhsData.LocalValues, lhsData.Degree, deg, grid);
    rhsVals = elevVals(obj, rhsData.LocalValues, rhsData.Degree, deg, grid);
    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) assignCell( ...
        helper.cellGet(lhsVals, subs), helper.cellGet(rhsVals, subs), rows, cols));

    hasDec = lhsData.ContainsDecision || rhsData.ContainsDecision;
    hasRate = lhsData.HasRateDependence || rhsData.HasRateDependence;
    if ~hasRate
        rb = [];
    end
    obj = dpvar(mkInit(grid, obj.MatrixSize, deg, vals, hasDec, hasRate, rb, "expression"));
end

function out = assignCell(lhs, rhs, rows, cols)
    out = cell(size(lhs));
    for k = 1:numel(lhs)
        val = lhs{k};
        val(rows, cols) = rhs{k};
        out{k} = val;
    end
end
