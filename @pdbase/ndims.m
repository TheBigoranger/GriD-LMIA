function n = ndims(~)
    %NDIMS Number of matrix dimensions represented by a pdbase object.
    %
    %   Syntax:
    %     n = ndims(obj)
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [2 3], 0);
    %     n = ndims(obj);

    n = 2;
end
