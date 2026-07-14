function out = triu(obj, k)
    %TRIU Upper triangular part of each coefficient payload.
    %
    %   Syntax:
    %     U = triu(A)
    %     U = triu(A, k)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {ones(2), 2 * ones(2)}, Degree=1);
    %     U = triu(A);

    if nargin < 2
        k = 0;
    end
    k = helper.chk(k, "pdmat:InvalidTriangularPart", ...
        "Diagonal offset must be a finite real integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer");
    k = double(k);
    out = unOp(obj, @(a) triu(a, k));
end
