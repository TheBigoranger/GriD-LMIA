function out = tril(obj, k)
    %TRIL Retain the lower triangular part of every coefficient matrix.
    %
    %   Syntax:
    %     out = tril(obj)
    %     out = tril(obj, k)
    %
    %   Arguments:
    %     k - Optional integer diagonal offset. The default is zero.
    %
    %   Output:
    %     out - Same dynamic class with tril applied to every coefficient.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {ones(2), 2*ones(2)}, Degree=1);
    %     L = tril(A);

    if nargin < 2
        k = 0;
    end
    prefix = string(class(obj));
    k = helper.chk(k, prefix + ":InvalidTriangularPart", ...
        "diagonal offset", ...
        "numeric", "real", "scalar", "finite", "integer");
    out = mapUnary(obj, @(a) tril(a, double(k)));
end
