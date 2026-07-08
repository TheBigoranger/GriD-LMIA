function out = diag(obj, k)
    %DIAG Diagonal extraction or construction for dpvar coefficients.
    %
    %   Syntax:
    %     d = diag(P)
    %     d = diag(P, k)
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "full");
    %     d = diag(P);

    if nargin < 2
        k = 0;
    end
    k = helper.chk(k, "dpvar:InvalidDiag", ...
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
            error("dpvar:InvalidDiag", ...
                "Diagonal offset selects an empty diagonal, which dpvar cannot store.");
        end
    end

    out = unOp(obj, @(a) diag(a, k));
end
