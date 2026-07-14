function n = width(obj)
    %WIDTH Number of matrix columns in the pdmat payload.
    %
    %   Syntax:
    %     n = width(A)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {zeros(2, 3), ones(2, 3)}, Degree=1);
    %     n = width(A);

    n = obj.MatrixSize(2);
end
