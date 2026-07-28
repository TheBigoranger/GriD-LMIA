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
    rb = obj.pickRateBounds("pdvar:InvalidAssignment", rhs);
    lhsData = asData(grid, obj, [], rb, ...
        "pdvar:InvalidAssignment");
    rhsData = asData(grid, rhs, [numel(rows), numel(cols)], ...
        rb, "pdvar:InvalidAssignment");

    deg = max(lhsData.Degree, rhsData.Degree);
    [lhsPlan, rhsPlan] = elevationPlans( ...
        lhsData.Degree, rhsData.Degree, deg, numel(grid));
    lhsVals = pdbase.elevLocalValues(lhsData.LocalValues, ...
        lhsData.Degree, deg, grid, lhsPlan, "fast");
    rhsVals = pdbase.elevLocalValues(rhsData.LocalValues, ...
        rhsData.Degree, deg, grid, rhsPlan, "fast");
    vals = obj.zipRateRows(lhsVals, rhsVals, ...
        @(lhs, rhs) assignBlock(lhs, rhs, rows, cols), grid, ...
        "pdvar:InvalidCoefficientRows");

    hasDec = lhsData.ContainsDecision || rhsData.ContainsDecision;
    hasRate = lhsData.HasRateDependence || rhsData.HasRateDependence;
    if ~hasRate
        rb = [];
    end
    obj = pdvar(mkInit(grid, obj.MatrixSize, deg, vals, hasDec, hasRate, rb, ...
        "expression", []));
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

function out = assignBlock(lhs, rhs, rows, cols)
    out = lhs;
    out(rows, cols) = rhs;
end
