function out = vec(obj)
    %VEC Vectorize every stored coefficient matrix in column-major order.
    %
    %   Syntax:
    %     out = vec(obj)
    %
    %   Output:
    %     out - Same dynamic class with each coefficient reshaped to a column
    %           vector.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {eye(2), 2*eye(2)}, Degree=1);
    %     v = vec(A);

    out = mapUnary(obj, @(a) a(:), [prod(obj.MatrixSize), 1]);
end
