function n = width(obj)
    %WIDTH Number of matrix columns in the stored payload.
    %
    %   Syntax:
    %     n = width(obj)
    %
    %   Output:
    %     n - Number of stored matrix columns.
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [2 3], 0);
    %     n = width(obj);

    n = obj.MatrixSize(2);
end
