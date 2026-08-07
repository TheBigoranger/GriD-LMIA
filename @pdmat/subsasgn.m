function obj = subsasgn(obj, S, rhs)
    %SUBSASGN In-bounds block replacement for coefficient-backed pdmat objects.
    %
    %   Syntax:
    %     A(rows, cols) = B
    %     A(rows, cols) = M
    %
    %   Output:
    %     A - Updated pdmat with the selected matrix block replaced in every
    %         aligned coefficient.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {zeros(2), eye(2)}, Degree=1);
    %     A(1, :) = [3 4];

    if ~strcmp(S(1).type, "()")
        obj = builtin("subsasgn", obj, S, rhs);
        return
    end

    [rows, cols] = sanChk(obj, S, rhs);
    rb = obj.pickRateBounds("pdmat:InvalidAssignment", rhs);
    grid = obj.mergeGrid("pdmat:MixedGrid", rhs);
    lhsData = normOperand(grid, obj, [], rb, "pdmat:InvalidAssignment");
    rhsData = normOperand(grid, rhs, [numel(rows), numel(cols)], rb, ...
        "pdmat:InvalidAssignment");

    deg = max(lhsData.Degree, rhsData.Degree);
    data = pdbase.elevData([lhsData, rhsData], deg, grid, "fast");
    lhsVals = data(1).LocalValues;
    rhsVals = data(2).LocalValues;
    vals = obj.zipRateRows(lhsVals, rhsVals, ...
        @(lhs, rhs) setBlock(lhs, rhs, rows, cols), grid, ...
        "pdmat:InvalidCoefficientRows");

    obj = mkCoeffObj(grid, vals, deg, rb, [], [], [], "fast", ...
        max(lhsData.NumRateRows, rhsData.NumRateRows));
end

function [rows, cols] = sanChk(obj, S, rhs)
    %SANCHK Validate the assignment form before coefficient conversion.
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
    [rows, cols] = pdbase.matSubs(S(1).subs, obj.MatrixSize, ...
        "pdmat:InvalidAssignment");
end

function out = setBlock(lhs, rhs, rows, cols)
    %ASSIGNBLOCK Replace one aligned matrix coefficient block.
    out = lhs;
    out(rows, cols) = rhs;
end
