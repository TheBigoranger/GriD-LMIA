function n = height(obj)
    %HEIGHT Number of matrix rows in the pdmat payload.
    %
    %   Syntax:
    %     n = height(A)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {zeros(2, 3), ones(2, 3)}, Degree=1);
    %     n = height(A);

    n = obj.MatrixSize(1);
end
