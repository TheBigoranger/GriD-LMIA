function out = binOp(lhs, rhs, fcn, errId)
    %BINOP Apply a same-size binary coefficient operation to pdmat operands.
    %
    %   Syntax:
    %     out = binOp(lhs, rhs, fcn, errId)
    %
    %   Arguments:
    %     lhs, rhs - pdmat or numeric operands.
    %     fcn      - Binary operation applied to aligned coefficients.
    %     errId    - Operation-specific validation identifier.
    %
    %   Output:
    %     out - Coefficient-backed pdmat result.
    %
    %   Example (via public algebra):
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     C = A + 1;
    %
    %   The pdmat operand supplies the dispatch metadata. Inputs are first
    %   moved to its common-refinement grid, then degree-elevated and combined
    %   cell by cell through FCN. Incompatible sizes, grids, or source modes
    %   are rejected by the conversion helpers. An all-zero result is kept in
    %   the compact degree-zero representation.

    if isa(lhs, "pdmat")
        anchor = lhs;
    else
        anchor = rhs;
    end
    % Use one pdmat operand as the metadata anchor for grid and size alignment.
    rb = anchor.pickRateBounds(errId, lhs, rhs);
    grid = anchor.mergeGrid("pdmat:MixedGrid", lhs, rhs);
    reqSize = anchor.MatrixSize;
    ld = asData(grid, lhs, reqSize, rb, errId);
    rd = asData(grid, rhs, reqSize, rb, errId);

    % Elevate both operands before applying the cell-local coefficient operation.
    deg = max(ld.Degree, rd.Degree);
    [lhsPlan, rhsPlan] = elevationPlans( ...
        ld.Degree, rd.Degree, deg, numel(grid));
    lhsVals = pdbase.elevLocalValues( ...
        ld.LocalValues, ld.Degree, deg, grid, lhsPlan, "fast");
    rhsVals = pdbase.elevLocalValues( ...
        rd.LocalValues, rd.Degree, deg, grid, rhsPlan, "fast");
    vals = anchor.zipRateRows(lhsVals, rhsVals, fcn, grid, ...
        "pdmat:InvalidCoefficientRows");

    if helper.isZero(vals, "vals")
        % Store an all-zero result in its compact representation.
        out = zeroObj(grid, reqSize);
        return
    end

    hasRate = ld.HasRateDependence || rd.HasRateDependence;
    if ~hasRate
        rb = [];
    end
    out = mkObj(grid, vals, deg, rb);
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
