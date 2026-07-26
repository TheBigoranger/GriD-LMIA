function out = fliplr(obj)
    %FLIPLR Reverse the columns of every stored coefficient matrix.

    out = unOp(obj, @(a) fliplr(a));
end
