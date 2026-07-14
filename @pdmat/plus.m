function out = plus(lhs, rhs)
    %PLUS Add coefficient-backed pdmat objects and numeric constants.
    %
    %   Syntax:
    %     C = A + B
    %     C = A + M
    %     C = M + A
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     C = A + 3;

    if isa(lhs, "pdmat") && helper.isZero(lhs, "obj") && isa(rhs, "pdmat")
        chkAddZero(lhs, rhs, "pdmat:InvalidAddition");
        out = rhs;
        return
    end
    if isa(lhs, "pdmat") && isa(rhs, "pdmat") && helper.isZero(rhs, "obj")
        chkAddZero(rhs, lhs, "pdmat:InvalidAddition");
        out = lhs;
        return
    end
    if isa(lhs, "pdmat") && helper.isZero(rhs, "add", lhs.MatrixSize)
        out = lhs;
        return
    end
    if isa(rhs, "pdmat") && helper.isZero(lhs, "add", rhs.MatrixSize)
        out = rhs;
        return
    end

    out = binOp(lhs, rhs, @(a, b) a + b, "pdmat:InvalidAddition");
end

function chkAddZero(zeroVal, other, errId)
    if ~isequal(zeroVal.MatrixSize, other.MatrixSize)
        error(errId, "pdmat matrix sizes are incompatible for this operation.");
    end
    zeroVal.mergeGrid("pdmat:MixedGrid", zeroVal, other);
end
