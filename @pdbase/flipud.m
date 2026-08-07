function out = flipud(obj)
    %FLIPUD Reverse the rows of every stored coefficient matrix.
    %
    %   Syntax:
    %     out = flipud(obj)
    %
    %   Output:
    %     out - Same dynamic class with each coefficient matrix reversed
    %           top-to-bottom.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1; 2], [2; 4]}, Degree=1);
    %     B = flipud(A);

    out = mapUnary(obj, @(a) flipud(a));
end
