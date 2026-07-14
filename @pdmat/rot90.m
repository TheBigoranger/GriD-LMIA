function out = rot90(obj, k)
    %ROT90 Rotate each coefficient payload by 90-degree increments.
    %
    %   Syntax:
    %     B = rot90(A)
    %     B = rot90(A, k)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2; 3 4], 2 * [1 2; 3 4]}, Degree=1);
    %     B = rot90(A);

    if nargin < 2
        k = 1;
    end
    k = helper.chk(k, "pdmat:InvalidRot90", ...
        "Rotation count must be a finite real integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer");
    out = unOp(obj, @(a) rot90(a, double(k)));
end
