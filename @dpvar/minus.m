function out = minus(lhs, rhs)
    %MINUS Subtract dpvar affine coefficient expressions.
    %
    %   Syntax:
    %     C = P - Q
    %     C = P - M
    %     C = M - P
    %
    %   Example:
    %     P = dpvar(2, {[0 1]});
    %     C = eye(2) - P;

    out = binOp(lhs, rhs, @(a, b) a - b, "dpvar:InvalidSubtraction");
end
