function out = ge(lhs, rhs)
    %GE Assemble a coefficient-wise nonnegative PD-LMI constraint.
    %
    %   Syntax:
    %     C = P >= Q
    %     C = P >= 0
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric");
    %     C = P >= 0;

    out = pdlmi(lhs - rhs, ">=");
end
