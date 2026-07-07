function out = tril(obj, k)
    %TRIL Lower triangular part of each dpvar coefficient payload.
    %
    %   Syntax:
    %     L = tril(P)
    %     L = tril(P, k)
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "full");
    %     L = tril(P);

    if nargin < 2
        k = 0;
    end
    k = helper.chk(k, "dpvar:InvalidTriangularPart", ...
        "Diagonal offset must be a finite real integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer");
    out = unOp(obj, @(a) tril(a, double(k)));
end
