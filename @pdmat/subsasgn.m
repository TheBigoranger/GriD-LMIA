function obj = subsasgn(obj, S, rhs)
    %SUBSASGN In-bounds block replacement for coefficient-backed pdmat objects.
    %
    %   Syntax:
    %     A(rows, cols) = B
    %     A(rows, cols) = M
    %
    %   Example:
    %     A = pdmat({[0 1]}, {zeros(2), eye(2)}, Degree=1);
    %     A(1, :) = [3 4];

    if ~strcmp(S(1).type, "()")
        obj = builtin("subsasgn", obj, S, rhs);
        return
    end

    [rows, cols] = sanCheck(obj, S, rhs);
    grid = obj.mergeGrid("pdmat:MixedGrid", rhs);
    lhsData = asData(grid, obj, [], "pdmat:InvalidAssignment");
    rhsData = asData(grid, rhs, [numel(rows), numel(cols)], "pdmat:InvalidAssignment");

    deg = max(lhsData.Degree, rhsData.Degree);
    lhsVals = elevLocalValues(obj, lhsData.LocalValues, lhsData.Degree, deg, grid);
    rhsVals = elevLocalValues(obj, rhsData.LocalValues, rhsData.Degree, deg, grid);
    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) assignCell( ...
        helper.cellGet(lhsVals, subs), helper.cellGet(rhsVals, subs), rows, cols));

    obj = mkObj(grid, vals, deg);
end

function [rows, cols] = sanCheck(obj, S, rhs)
    %SANCHECK Validate the assignment form before coefficient conversion.
    if numel(S) ~= 1
        error("pdmat:UnsupportedAssignment", ...
            "pdmat only supports direct two-dimensional block assignment.");
    end
    if isnumeric(rhs) && isempty(rhs)
        error("pdmat:UnsupportedAssignment", ...
            "pdmat does not support deletion assignment.");
    end

    if obj.SourceSummary == "function"
        error("pdmat:FunctionOnlyAlgebra", ...
            "Function-backed pdmat objects need explicit Bernstein coefficient evidence for this operation.");
    end
    [rows, cols] = helper.matSubs(S(1).subs, obj.MatrixSize, ...
        "pdmat:InvalidAssignment");
end

function out = assignCell(lhs, rhs, rows, cols)
    out = cell(size(lhs));
    for k = 1:numel(lhs)
        val = lhs{k};
        val(rows, cols) = rhs{k};
        out{k} = val;
    end
end
