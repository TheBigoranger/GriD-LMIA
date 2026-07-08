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

if isa(lhs, "dpmat") && isa(rhs, "dpmat") && isZeroObj(rhs)
    chkAddZero(rhs, lhs, "dpmat:InvalidSubtraction");
    out = lhs;
    return
end
if isa(lhs, "dpmat") && isZeroAdd(rhs, lhs.MatrixSize)
    out = lhs;
    return
end
if isa(lhs, "dpmat") && isa(rhs, "dpmat") && isequal(lhs, rhs)
    out = zeroObj(lhs.GridInfo.Vectors, lhs.MatrixSize);
    return
end

out = binOp(lhs, rhs, @(a, b) a - b, "dpmat:InvalidSubtraction");
end

function chkAddZero(zeroVal, other, errId)
    if ~isequal(zeroVal.MatrixSize, other.MatrixSize)
        error(errId, "dpmat matrix sizes are incompatible for this operation.");
    end
    zeroVal.mergeGrid("dpmat:MixedGrid", zeroVal, other);
end
