function out = flip(obj, dim)
    %FLIP Reverse each pdvar coefficient payload along a matrix dimension.
    %
    %   Syntax:
    %     Q = flip(P)
    %     Q = flip(P, dim)
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "full");
    %     Q = flip(P, 2);

    if nargin < 2
        out = unOp(obj, @(a) flip(a));
        return
    end

    dim = helper.chk(dim, "pdvar:InvalidFlip", ...
        "Flip dimension must be a positive integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "positive");
    out = unOp(obj, @(a) flip(a, double(dim)));
end
