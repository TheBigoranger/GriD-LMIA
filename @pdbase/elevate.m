function out = elevate(obj, degreeIncrement)
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
    %   rejected by the same validation used by elevVals.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 3}, Degree=1);
    %     B = A.elevate(1);

    vals = obj.elevVals(degreeIncrement);

    % pdbase owns these private-set properties, so updating a value-class copy
    % preserves every subclass-specific property without reconstruction.
    out = obj;
    inc = helper.normalizeDegree(degreeIncrement, obj.npar(), ...
        "pdbase:InvalidDegreeIncrement", "degreeIncrement");
    out.Degree = obj.Degree + inc;
    out.LocalValues = vals;
end
