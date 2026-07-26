function out = diag(obj, k)
    %DIAG Extract or construct a diagonal in every coefficient matrix.

    if nargin < 2
        k = 0;
    end
    prefix = string(class(obj));
    k = helper.chk(k, prefix + ":InvalidDiag", ...
        "Diagonal offset must be a finite real integer scalar.", ...
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

    out = unOp(obj, @(a) diag(a, k));
end
