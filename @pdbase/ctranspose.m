function out = ctranspose(obj)
    %CTRANSPOSE Conjugate-transpose every stored coefficient matrix.

    out = unOp(obj, @(a) a', fliplr(obj.MatrixSize));
end
