function out = diag(obj, k)
    %DIAG Diagonal extraction or construction for coefficient-backed dpmat.
    %
    %   Syntax:
    %     d = diag(A)
    %     d = diag(A, k)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    %     d = diag(A);

    if nargin < 2
        k = 0;
    end
    k = helper.chk(k, "dpmat:InvalidDiag", ...
        "Diagonal offset must be a finite real integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer");
    k = double(k);
    chkDiagSize(obj.MatrixSize, k);

    out = unOp(obj, @(a) diag(a, k));
end

function chkDiagSize(sz, k)
    if sz(1) == 1 || sz(2) == 1
        return
    end
    if k >= 0
        n = min(sz(1), sz(2) - k);
    else
        n = min(sz(1) + k, sz(2));
    end
    if n < 1
        error("dpmat:InvalidDiag", ...
            "Diagonal offset selects an empty diagonal, which dpmat cannot store.");
    end
end
