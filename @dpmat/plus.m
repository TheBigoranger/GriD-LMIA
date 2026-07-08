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

    if isa(lhs, "dpmat") && isZeroObj(lhs) && isa(rhs, "dpmat")
        chkAddZero(lhs, rhs, "dpmat:InvalidAddition");
        out = rhs;
        return
    end
    if isa(lhs, "dpmat") && isa(rhs, "dpmat") && isZeroObj(rhs)
        chkAddZero(rhs, lhs, "dpmat:InvalidAddition");
        out = lhs;
        return
    end
    if isa(lhs, "dpmat") && isZeroAdd(rhs, lhs.MatrixSize)
        out = lhs;
        return
    end
    if isa(rhs, "dpmat") && isZeroAdd(lhs, rhs.MatrixSize)
        out = rhs;
        return
    end

    out = binOp(lhs, rhs, @(a, b) a + b, "dpmat:InvalidAddition");
end

function chkAddZero(zeroVal, other, errId)
    if ~isequal(zeroVal.MatrixSize, other.MatrixSize)
        error(errId, "dpmat matrix sizes are incompatible for this operation.");
    end
    zeroVal.mergeGrid("dpmat:MixedGrid", zeroVal, other);
end
