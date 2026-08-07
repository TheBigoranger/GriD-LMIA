function n = length(obj)
    %LENGTH Largest matrix dimension of the stored payload.
    %
    %   Syntax:
    %     n = length(obj)
    %
    %   Output:
    %     n - Larger of the stored row and column counts.
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [2 3], 0);
    %     n = length(obj);

    n = max(obj.MatrixSize);
end
