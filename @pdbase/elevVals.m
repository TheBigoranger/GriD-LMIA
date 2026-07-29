function vals = elevVals(obj, degreeIncrement, validationMode)
    %ELEVVALS Return this object's coefficients in an elevated Bernstein basis.
    %
    %   Syntax:
    %     vals = obj.elevVals(degreeIncrement)
    %
    %   Arguments:
    %     degreeIncrement - Scalar shorthand or ell-element nonnegative increment.
    %
    %   Output:
    %     vals - Elevated LocalValues tree; obj is unchanged.
    %
    %   vals = obj.elevVals(degreeIncrement) preserves the represented
    %   polynomial, physical-cell tree, and rate-row ordering while adding the
    %   increment componentwise. Scalar input expands uniformly. The object is unchanged.
    %   Invalid increments raise pdbase:InvalidDegreeIncrement. Function-only
    %   pdmat sources have no coefficient evidence and raise
    %   pdbase:MissingCoefficientEvidence.
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [1 1], 1, {{0, 1}});
    %     vals = obj.elevVals(1);  % vals{1} is {0, 0.5, 1}

    if nargin < 3
        validationMode = "fast";
    else
        validationMode = normalizeValidationMode(validationMode);
    end

    inc = helper.normalizeDegree(degreeIncrement, obj.npar(), ...
        "pdbase:InvalidDegreeIncrement", "degreeIncrement");
    if obj.SourceSummary == "function"
        error("pdbase:MissingCoefficientEvidence", ...
            "Degree elevation requires stored Bernstein coefficient evidence.");
    end

    vals = pdbase.elevLocalValues(obj.LocalValues, obj.Degree, ...
        obj.Degree + inc, obj.GridInfo.Vectors, [], validationMode);
end

function mode = normalizeValidationMode(value)
    % The optional mode is an internal call-local bridge for certificate
    % assembly; it is deliberately not stored on or inherited from obj.
    if ~((ischar(value) && isrow(value) && ~isempty(value)) || ...
            (isstring(value) && isscalar(value) && ~ismissing(value)))
        error("pdbase:InvalidValidationMode", ...
            "ValidationMode must be the scalar text 'fast' or 'strict'.");
    end
    mode = lower(string(value));
    if ~any(mode == ["fast", "strict"])
        error("pdbase:InvalidValidationMode", ...
            "ValidationMode must be the scalar text 'fast' or 'strict'.");
    end
end
