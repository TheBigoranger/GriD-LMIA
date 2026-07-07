function out = tril(obj, k)
    %TRIL Lower triangular part of each coefficient payload.
    %
    %   Syntax:
    %     L = tril(A)
    %     L = tril(A, k)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {ones(2), 2 * ones(2)}, Degree=1);
    %     L = tril(A);

    if nargin < 2
        k = 0;
    end
    k = helper.chk(k, "dpmat:InvalidTriangularPart", ...
        "Diagonal offset must be a finite real integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer");
    k = double(k);
    out = unOp(obj, @(a) tril(a, k));
end
