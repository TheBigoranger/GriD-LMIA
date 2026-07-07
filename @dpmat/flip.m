function out = flip(obj, dim)
    %FLIP Reverse each coefficient payload along a matrix dimension.
    %
    %   Syntax:
    %     B = flip(A)
    %     B = flip(A, dim)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {[1 2; 3 4], 2 * [1 2; 3 4]}, Degree=1);
    %     B = flip(A, 2);

    if nargin < 2
        out = unOp(obj, @(a) flip(a));
        return
    end

    dim = helper.chk(dim, "dpmat:InvalidFlip", ...
        "Flip dimension must be a positive integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "positive");
    out = unOp(obj, @(a) flip(a, double(dim)));
end
