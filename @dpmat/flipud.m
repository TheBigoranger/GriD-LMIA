function out = flipud(obj)
    %FLIPUD Flip each coefficient payload up to down.
    %
    %   Syntax:
    %     B = flipud(A)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {[1 2; 3 4], 2 * [1 2; 3 4]}, Degree=1);
    %     B = flipud(A);

    out = unOp(obj, @(a) flipud(a));
end
