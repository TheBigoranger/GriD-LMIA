function out = triu(obj, k)
    %TRIU Retain the upper triangular part of every coefficient matrix.
    %
    %   Syntax:
    %     out = triu(obj)
    %     out = triu(obj, k)
    %
    %   Arguments:
    %     k - Optional integer diagonal offset. The default is zero.
    %
    %   Output:
    %     out - Same dynamic class with triu applied to every coefficient.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {ones(2), 2*ones(2)}, Degree=1);
    %     U = triu(A);

    if nargin < 2
        k = 0;
    end
    prefix = string(class(obj));
    k = helper.chk(k, prefix + ":InvalidTriangularPart", ...
        "diagonal offset", ...
        "numeric", "real", "scalar", "finite", "integer");
    out = mapUnary(obj, @(a) triu(a, double(k)));
end
