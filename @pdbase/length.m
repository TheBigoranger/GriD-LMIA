function n = length(obj)
    %LENGTH Largest matrix dimension of the stored payload.
    %
    %   Syntax:
    %     n = length(obj)
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [2 3], 0);
    %     n = length(obj);

    n = max(obj.MatrixSize);
end
