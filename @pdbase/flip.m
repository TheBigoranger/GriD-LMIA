function out = flip(obj, dim)
    %FLIP Reverse every coefficient matrix along one matrix dimension.

    if nargin < 2
        out = unOp(obj, @(a) flip(a));
        return
    end

    prefix = string(class(obj));
    dim = helper.chk(dim, prefix + ":InvalidFlip", ...
        "Flip dimension must be a positive integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "positive");
    out = unOp(obj, @(a) flip(a, double(dim)));
end
