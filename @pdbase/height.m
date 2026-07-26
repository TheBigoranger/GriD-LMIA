function n = height(obj)
    %HEIGHT Number of matrix rows in the stored payload.
    %
    %   Syntax:
    %     n = height(obj)
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [2 3], 0);
    %     n = height(obj);

    n = obj.MatrixSize(1);
end
