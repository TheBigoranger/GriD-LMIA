function out = triu(obj, k)
    %TRIU Upper triangular part of each pdvar coefficient payload.
    %
    %   Syntax:
    %     U = triu(P)
    %     U = triu(P, k)
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "full");
    %     U = triu(P);

    if nargin < 2
        k = 0;
    end
    k = helper.chk(k, "pdvar:InvalidTriangularPart", ...
        "Diagonal offset must be a finite real integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer");
    out = unOp(obj, @(a) triu(a, double(k)));
end
