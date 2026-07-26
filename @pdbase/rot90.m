function out = rot90(obj, k)
    %ROT90 Rotate every coefficient matrix by 90-degree increments.

    if nargin < 2
        k = 1;
    end
    prefix = string(class(obj));
    k = helper.chk(k, prefix + ":InvalidRot90", ...
        "Rotation count must be a finite real integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer");
    out = unOp(obj, @(a) turn(a, k));
end

function val = turn(val, k)
    %TURN Use one-argument rotations supported by both numeric and sdpvar.
    for j = 1:mod(double(k), 4)
        val = rot90(val);
    end
end
