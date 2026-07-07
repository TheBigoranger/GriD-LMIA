function out = plus(lhs, rhs)
    %PLUS Add coefficient-backed dpmat objects and numeric constants.
    %
    %   Syntax:
    %     C = A + B
    %     C = A + M
    %     C = M + A
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     C = A + 3;

    out = binOp(lhs, rhs, @(a, b) a + b, "dpmat:InvalidAddition");
end
