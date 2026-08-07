function out = transpose(obj)
    %TRANSPOSE Transpose every stored coefficient matrix.
    %
    %   Syntax:
    %     out = obj.'
    %
    %   Output:
    %     out - Same dynamic class with transposed matrix payloads.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2], [2 4]}, Degree=1);
    %     B = A.';

    out = mapUnary(obj, @(a) a.', fliplr(obj.MatrixSize));
end
