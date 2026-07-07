function n = length(obj)
    %LENGTH Largest matrix dimension of the dpmat payload.
    %
    %   Syntax:
    %     n = length(A)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {zeros(2, 3), ones(2, 3)}, Degree=1);
    %     n = length(A);

    n = max(obj.MatrixSize);
end
