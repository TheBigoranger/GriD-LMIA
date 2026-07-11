function vals = elevVals(obj, degreeIncrement)
    %ELEVVALS Return this object's coefficients in an elevated Bernstein basis.
    %
    %   Syntax:
    %     vals = obj.elevVals(degreeIncrement)
    %
    %   vals = obj.elevVals(degreeIncrement) preserves the represented
    %   polynomial, physical-cell tree, and rate-row ordering while adding
    %   degreeIncrement to every parameter direction. The object is unchanged.
    %   Invalid increments raise dpbase:InvalidDegreeIncrement. Function-only
    %   dpmat sources have no coefficient evidence and raise
    %   dpbase:MissingCoefficientEvidence.
    %
    %   Example:
    %     obj = dpbase({[0 1]}, [1 1], 1, {{0, 1}});
    %     vals = obj.elevVals(1);  % vals{1} is {0, 0.5, 1}

    inc = double(helper.chk(degreeIncrement, ...
        "dpbase:InvalidDegreeIncrement", ...
        "degreeIncrement must be a finite nonnegative integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
    if obj.SourceSummary == "function"
        error("dpbase:MissingCoefficientEvidence", ...
            "Degree elevation requires stored Bernstein coefficient evidence.");
    end

    vals = obj.elevLocalValues(obj.LocalValues, obj.Degree, ...
        obj.Degree + inc, obj.GridInfo.Vectors);
end
