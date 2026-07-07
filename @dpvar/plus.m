function out = plus(lhs, rhs)
    %PLUS Add dpvar affine coefficient expressions.
    %
    %   Syntax:
    %     C = P + Q
    %     C = P + M
    %     C = M + P
    %
    %   Example:
    %     P = dpvar(2, {[0 1]});
    %     C = P + eye(2);

    out = binOp(lhs, rhs, @(a, b) a + b, "dpvar:InvalidAddition");
end
