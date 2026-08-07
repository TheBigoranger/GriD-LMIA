function out = diag(obj, k)
    %DIAG Extract or construct a diagonal in every coefficient matrix.
    %
    %   Syntax:
    %     out = diag(obj)
    %     out = diag(obj, k)
    %
    %   Arguments:
    %     k - Optional integer diagonal offset. The default is zero.
    %
    %   Output:
    %     out - Same dynamic class with diag applied to every coefficient
    %           matrix.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {eye(2), 2*eye(2)}, Degree=1);
    %     d = diag(A);

    if nargin < 2
        k = 0;
    end
    prefix = string(class(obj));
    k = helper.chk(k, prefix + ":InvalidDiag", ...
        "diagonal offset", ...
        "numeric", "real", "scalar", "finite", "integer");
    k = double(k);

    % A matrix offset must select a nonempty diagonal because the shared
    % representation cannot store an empty matrix payload.
    sz = obj.MatrixSize;
    if sz(1) > 1 && sz(2) > 1
        if k >= 0
            n = min(sz(1), sz(2) - k);
        else
            n = min(sz(1) + k, sz(2));
        end
        if n < 1
            error(prefix + ":InvalidDiag", ...
                "Diagonal offset selects an empty diagonal, which %s cannot store.", ...
                prefix);
        end
    end

    out = mapUnary(obj, @(a) diag(a, k));
end
