function out = fliplr(obj)
    %FLIPLR Flip each coefficient payload left to right.
    %
    %   Syntax:
    %     B = fliplr(A)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {[1 2; 3 4], 2 * [1 2; 3 4]}, Degree=1);
    %     B = fliplr(A);

    out = unOp(obj, @(a) fliplr(a));
end
