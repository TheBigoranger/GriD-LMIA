function obj = subsasgn(obj, S, rhs)
    %SUBSASGN In-bounds block replacement for coefficient-backed dpmat objects.
    %
    %   Syntax:
    %     A(rows, cols) = B
    %     A(rows, cols) = M
    %
    %   Example:
    %     A = dpmat({[0 1]}, {zeros(2), eye(2)}, Degree=1);
    %     A(1, :) = [3 4];

    if ~strcmp(S(1).type, "()")
        obj = builtin("subsasgn", obj, S, rhs);
        return
    end
    if numel(S) ~= 1
        error("dpmat:UnsupportedAssignment", ...
            "dpmat only supports direct two-dimensional block assignment.");
    end
    if isnumeric(rhs) && isempty(rhs)
        error("dpmat:UnsupportedAssignment", ...
            "dpmat does not support deletion assignment.");
    end

    if obj.SourceSummary == "function"
        error("dpmat:FunctionOnlyAlgebra", ...
            "Function-backed dpmat objects need explicit Bernstein coefficient evidence for this operation.");
    end
    [rows, cols] = matSubs(S(1).subs, obj.MatrixSize, "dpmat:InvalidAssignment");
    grid = obj.mergeGrid("dpmat:MixedGrid", rhs);
    lhsData = asData(grid, obj, [], "dpmat:InvalidAssignment");
    rhsData = asData(grid, rhs, [numel(rows), numel(cols)], "dpmat:InvalidAssignment");

    deg = max(lhsData.Degree, rhsData.Degree);
    lhsVals = elevVals(obj, lhsData.LocalValues, lhsData.Degree, deg, grid);
    rhsVals = elevVals(obj, rhsData.LocalValues, rhsData.Degree, deg, grid);
    nCell = cellfun(@numel, grid) - 1;
    vals = internal.mkNest(nCell, @(subs) assignCell( ...
        internal.cellGet(lhsVals, subs), internal.cellGet(rhsVals, subs), rows, cols));

    obj = dpmat(grid, vals, Degree=deg);
end

function out = assignCell(lhs, rhs, rows, cols)
    out = cell(size(lhs));
    for k = 1:numel(lhs)
        val = lhs{k};
        val(rows, cols) = rhs{k};
        out{k} = val;
    end
end
