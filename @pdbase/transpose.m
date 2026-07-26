function out = transpose(obj)
    %TRANSPOSE Transpose every stored coefficient matrix.

    out = unOp(obj, @(a) a.', fliplr(obj.MatrixSize));
end
