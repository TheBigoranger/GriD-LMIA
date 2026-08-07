function n = ndims(~)
    %NDIMS Number of matrix dimensions represented by a pdbase object.
    %
    %   Syntax:
    %     n = ndims(obj)
    %
    %   Output:
    %     n - Always 2 because pdbase stores matrix payloads.
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [2 3], 0);
    %     n = ndims(obj);

    n = 2;
end
