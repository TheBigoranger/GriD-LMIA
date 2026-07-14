function out = diag(obj, k)
    %DIAG Diagonal extraction or construction for pdvar coefficients.
    %
    %   Syntax:
    %     d = diag(P)
    %     d = diag(P, k)
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "full");
    %     d = diag(P);

    if nargin < 2
        k = 0;
    end
    k = helper.chk(k, "pdvar:InvalidDiag", ...
        "Diagonal offset must be a finite real integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer");
    k = double(k);
    sz = obj.MatrixSize;
    if sz(1) > 1 && sz(2) > 1
        if k >= 0
            n = min(sz(1), sz(2) - k);
        else
            n = min(sz(1) + k, sz(2));
        end
        if n < 1
            error("pdvar:InvalidDiag", ...
                "Diagonal offset selects an empty diagonal, which pdvar cannot store.");
        end
    end

    out = unOp(obj, @(a) diag(a, k));
end
