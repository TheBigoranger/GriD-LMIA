function out = elevate(obj, degreeIncrement)
    %ELEVATE Return the same object in an elevated Bernstein basis.
    %
    %   Syntax:
    %     out = obj.elevate(degreeIncrement)
    %
    %   Arguments:
    %     degreeIncrement - Nonnegative degree added in every parameter.
    %
    %   Output:
    %     out - Same dynamic class with elevated coefficient evidence.
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
    out.Degree = obj.Degree + double(degreeIncrement);
    out.LocalValues = vals;
end
