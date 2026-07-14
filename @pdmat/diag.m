function out = diag(obj, k)
    %DIAG Diagonal extraction or construction for coefficient-backed pdmat.
    %
    %   Syntax:
    %     d = diag(A)
    %     d = diag(A, k)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    %     d = diag(A);

    if nargin < 2
        k = 0;
    end
    k = helper.chk(k, "pdmat:InvalidDiag", ...
        "Diagonal offset must be a finite real integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer");
    k = double(k);
    % check that the diagonal offset is valid for the matrix size
    % (i.e., that it selects a non-empty diagonal)
    sz = obj.MatrixSize;
    if sz(1) ~= 1 && sz(2) ~= 1
        if k >= 0
            n = min(sz(1), sz(2) - k);
        else
            n = min(sz(1) + k, sz(2));
        end
        if n < 1
            error("pdmat:InvalidDiag", ...
                "Diagonal offset selects an empty diagonal, which pdmat cannot store.");
        end
    end

    out = unOp(obj, @(a) diag(a, k));
end
