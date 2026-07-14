function out = cumsum(obj, dim)
    %CUMSUM Cumulative sum of each pdvar coefficient payload.
    %
    %   Syntax:
    %     C = cumsum(P)
    %     C = cumsum(P, dim)
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "full");
    %     C = cumsum(P, 2);

    if nargin < 2
        out = unOp(obj, @(a) cumsum(a));
        return
    end

    dim = helper.chk(dim, "pdvar:InvalidCumsum", ...
        "Cumulative-sum dimension must be a positive integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "positive");
    out = unOp(obj, @(a) cumsum(a, double(dim)));
end
