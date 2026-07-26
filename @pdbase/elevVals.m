function vals = elevVals(obj, degreeIncrement)
    %ELEVVALS Return this object's coefficients in an elevated Bernstein basis.
    %
    %   Syntax:
    %     vals = obj.elevVals(degreeIncrement)
    %
    %   Arguments:
    %     degreeIncrement - Nonnegative degree added in every parameter.
    %
    %   Output:
    %     vals - Elevated LocalValues tree; obj is unchanged.
    %
    %   vals = obj.elevVals(degreeIncrement) preserves the represented
    %   polynomial, physical-cell tree, and rate-row ordering while adding
    %   degreeIncrement to every parameter direction. The object is unchanged.
    %   Invalid increments raise pdbase:InvalidDegreeIncrement. Function-only
    %   pdmat sources have no coefficient evidence and raise
    %   pdbase:MissingCoefficientEvidence.
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [1 1], 1, {{0, 1}});
    %     vals = obj.elevVals(1);  % vals{1} is {0, 0.5, 1}

    inc = double(helper.chk(degreeIncrement, ...
        "pdbase:InvalidDegreeIncrement", ...
        "degreeIncrement must be a finite nonnegative integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
    if obj.SourceSummary == "function"
        error("pdbase:MissingCoefficientEvidence", ...
            "Degree elevation requires stored Bernstein coefficient evidence.");
    end

    vals = pdbase.elevLocalValues(obj.LocalValues, obj.Degree, ...
        obj.Degree + inc, obj.GridInfo.Vectors);
end
