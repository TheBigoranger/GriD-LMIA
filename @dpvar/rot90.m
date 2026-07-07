function out = rot90(obj, k)
    %ROT90 Rotate each dpvar coefficient payload by 90-degree increments.
    %
    %   Syntax:
    %     Q = rot90(P)
    %     Q = rot90(P, k)
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "full");
    %     Q = rot90(P);

    if nargin < 2
        k = 1;
    end
    k = helper.chk(k, "dpvar:InvalidRot90", ...
        "Rotation count must be a finite real integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer");
    out = unOp(obj, @(a) turn(a, k));
end

function val = turn(val, k)
    % YALMIP's sdpvar rot90 accepts one argument, so emulate MATLAB's k form.
    for j = 1:mod(double(k), 4)
        val = rot90(val);
    end
end
