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

    [rows, cols] = sanChk(obj, S, rhs);
    rb = obj.pickRateBounds("pdmat:InvalidAssignment", rhs);
    grid = obj.mergeGrid("pdmat:MixedGrid", rhs);
    lhsData = asData(grid, obj, [], rb, "pdmat:InvalidAssignment");
    rhsData = asData(grid, rhs, [numel(rows), numel(cols)], rb, ...
        "pdmat:InvalidAssignment");

    deg = max(lhsData.Degree, rhsData.Degree);
    [lhsPlan, rhsPlan] = elevationPlans( ...
        lhsData.Degree, rhsData.Degree, deg, numel(grid));
    lhsVals = pdbase.elevLocalValues(lhsData.LocalValues, ...
        lhsData.Degree, deg, grid, lhsPlan, "fast");
    rhsVals = pdbase.elevLocalValues(rhsData.LocalValues, ...
        rhsData.Degree, deg, grid, rhsPlan, "fast");
    vals = obj.zipRateRows(lhsVals, rhsVals, ...
        @(lhs, rhs) assignBlock(lhs, rhs, rows, cols), grid, ...
        "pdmat:InvalidCoefficientRows");

    hasRate = lhsData.HasRateDependence || rhsData.HasRateDependence;
    if ~hasRate
        rb = [];
    end
    obj = mkObj(grid, vals, deg, rb);
end

function [lhsPlan, rhsPlan] = elevationPlans(lhsDegree, rhsDegree, targetDegree, nPar)
    %ELEVATIONPLANS Reuse one map when both operands share a source degree.
    lhsPlan = [];
    rhsPlan = [];
    if lhsDegree < targetDegree
        lhsPlan = pdbase.elevationPlan(lhsDegree, targetDegree, nPar);
    end
    if rhsDegree < targetDegree
        if rhsDegree == lhsDegree
            rhsPlan = lhsPlan;
        else
            rhsPlan = pdbase.elevationPlan(rhsDegree, targetDegree, nPar);
        end
    end
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

function out = assignBlock(lhs, rhs, rows, cols)
    %ASSIGNBLOCK Replace one aligned matrix coefficient block.
    out = lhs;
    out(rows, cols) = rhs;
end
