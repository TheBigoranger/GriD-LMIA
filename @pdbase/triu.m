function out = triu(obj, k)
    %TRIU Retain the upper triangular part of every coefficient matrix.

    if nargin < 2
        k = 0;
    end
    prefix = string(class(obj));
    k = helper.chk(k, prefix + ":InvalidTriangularPart", ...
        "Diagonal offset must be a finite real integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer");
    out = unOp(obj, @(a) triu(a, double(k)));
end
