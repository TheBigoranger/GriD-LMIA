function out = flipud(obj)
    %FLIPUD Reverse the rows of every stored coefficient matrix.

    out = unOp(obj, @(a) flipud(a));
end
