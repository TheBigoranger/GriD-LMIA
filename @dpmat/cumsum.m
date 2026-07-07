function out = cumsum(obj, dim)
    %CUMSUM Cumulative sum of each coefficient payload.
    %
    %   Syntax:
    %     C = cumsum(A)
    %     C = cumsum(A, dim)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {[1 2; 3 4], 2 * [1 2; 3 4]}, Degree=1);
    %     C = cumsum(A, 2);

    if nargin < 2
        out = unOp(obj, @(a) cumsum(a));
        return
    end

    dim = helper.chk(dim, "dpmat:InvalidCumsum", ...
        "Cumulative-sum dimension must be a positive integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "positive");
    out = unOp(obj, @(a) cumsum(a, double(dim)));
end
