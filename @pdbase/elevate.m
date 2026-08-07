function out = elevate(obj, degreeIncrement, validationMode)
    %ELEVATE Return the same object in an elevated Bernstein basis.
    %
    %   Syntax:
    %     out = obj.elevate(degreeIncrement)
    %
    %   Arguments:
    %     degreeIncrement - Scalar shorthand or ell-element nonnegative increment.
    %
    %   Output:
    %     out - Same dynamic class with componentwise-elevated coefficient evidence.
    %
    %   elevate preserves the represented polynomial, object metadata, YALMIP
    %   variables, physical cells, and rate-row order. The source object is
    %   unchanged. Function-only pdmat data has no coefficient evidence and is
    %   rejected when no coefficient evidence is stored.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 3}, Degree=1);
    %     B = A.elevate(1);

    if nargin < 3
        validationMode = "fast";
    end
    inc = helper.normDeg(degreeIncrement, obj.npar(), ...
        "pdbase:InvalidDegreeIncrement", "degreeIncrement");
    if obj.SourceSummary == "function"
        error("pdbase:MissingCoefficientEvidence", ...
            "Degree elevation requires stored Bernstein coefficient evidence.");
    end

    data = struct("Degree", obj.Degree, ...
        "LocalValues", {obj.LocalValues}, ...
        "NumRateRows", obj.NumRateRows);
    data = pdbase.elevData(data, obj.Degree + inc, ...
        obj.GridInfo.Vectors, validationMode);

    % Updating a value-class copy preserves subclass metadata and decisions.
    out = obj;
    out.Degree = obj.Degree + inc;
    out.LocalValues = data.LocalValues;
end
