function out = fliplr(obj)
    %FLIPLR Reverse the columns of every stored coefficient matrix.
    %
    %   Syntax:
    %     out = fliplr(obj)
    %
    %   Output:
    %     out - Same dynamic class with each coefficient matrix reversed
    %           left-to-right.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2], [2 4]}, Degree=1);
    %     B = fliplr(A);

    out = mapUnary(obj, @(a) fliplr(a));
end
