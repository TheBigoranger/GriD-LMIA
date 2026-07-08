function out = le(lhs, rhs)
    %LE Assemble a coefficient-wise nonpositive DP-LMI constraint.
    %
    %   Syntax:
    %     C = P <= Q
    %     C = P <= 0
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "symmetric");
    %     C = P <= 0;

    out = dplmi(lhs - rhs, "<=");
end
