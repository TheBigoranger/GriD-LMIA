function out = minus(lhs, rhs)
%MINUS Subtract coefficient-backed dpmat objects and numeric constants.
%
%   Syntax:
%     C = A - B
%     C = A - M
%     C = M - A
%
%   Example:
%     A = dpmat({[0 1]}, {1, 2}, Degree=1);
%     C = 5 - A;

out = binOp(lhs, rhs, @(a, b) a - b, "dpmat:InvalidSubtraction");
end
