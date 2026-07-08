function out = ge(lhs, rhs)
    %GE Assemble a coefficient-wise nonnegative DP-LMI constraint.
    %
    %   Syntax:
    %     C = P >= Q
    %     C = P >= 0
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "symmetric");
    %     C = P >= 0;

    out = dplmi(lhs - rhs, ">=");
end
