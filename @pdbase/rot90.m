function out = rot90(obj, k)
    %ROT90 Rotate every coefficient matrix by 90-degree increments.
    %
    %   Syntax:
    %     out = rot90(obj)
    %     out = rot90(obj, k)
    %
    %   Arguments:
    %     k - Optional integer number of 90-degree rotations. The default is 1.
    %
    %   Output:
    %     out - Same dynamic class with rotated coefficient matrices.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2; 3 4], [2 4; 6 8]}, Degree=1);
    %     B = rot90(A, 2);

    if nargin < 2
        k = 1;
    end
    prefix = string(class(obj));
    k = helper.chk(k, prefix + ":InvalidRot90", ...
        "rotation count", ...
        "numeric", "real", "scalar", "finite", "integer");
    out = mapUnary(obj, @(a) turn(a, k));
end

function val = turn(val, k)
    %TURN Use one-argument rotations supported by both numeric and sdpvar.
    for j = 1:mod(double(k), 4)
        val = rot90(val);
    end
end
