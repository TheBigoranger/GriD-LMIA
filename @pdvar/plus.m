function out = plus(lhs, rhs)
    %PLUS Add pdvar affine coefficient expressions.
    %
    %   Syntax:
    %     C = P + Q
    %     C = P + M
    %     C = M + P
    %
    %   Example:
    %     P = pdvar(2, {[0 1]});
    %     C = P + eye(2);

    if isa(lhs, "pdvar") && helper.isZero(lhs, "obj") && isa(rhs, "pdvar")
        chkAddZero(lhs, rhs, "pdvar:InvalidAddition");
        out = rhs;
        return
    end
    if isa(lhs, "pdvar") && isa(rhs, "pdvar") && helper.isZero(rhs, "obj")
        chkAddZero(rhs, lhs, "pdvar:InvalidAddition");
        out = lhs;
        return
    end
    if isa(lhs, "pdvar") && isa(rhs, "pdmat") && helper.isZero(rhs, "obj")
        chkAddZero(rhs, lhs, "pdvar:InvalidAddition");
        out = lhs;
        return
    end
    if isa(lhs, "pdmat") && helper.isZero(lhs, "obj") && isa(rhs, "pdvar")
        chkAddZero(lhs, rhs, "pdvar:InvalidAddition");
        out = rhs;
        return
    end
    if isa(lhs, "pdvar") && helper.isZero(rhs, "add", lhs.MatrixSize)
        out = lhs;
        return
    end
    if isa(rhs, "pdvar") && helper.isZero(lhs, "add", rhs.MatrixSize)
        out = rhs;
        return
    end

    out = binOp(lhs, rhs, @(a, b) a + b, "pdvar:InvalidAddition");
end

function chkAddZero(zeroVal, other, errId)
    if ~isequal(zeroVal.MatrixSize, other.MatrixSize)
        error(errId, "pdvar operand matrix sizes are incompatible for this operation.");
    end
    other.mergeGrid("pdvar:MixedGrid", zeroVal, other);
end
