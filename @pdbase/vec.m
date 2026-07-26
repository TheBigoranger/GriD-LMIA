function out = vec(obj)
    %VEC Vectorize every stored coefficient matrix in column-major order.

    out = unOp(obj, @(a) a(:), [prod(obj.MatrixSize), 1]);
end
