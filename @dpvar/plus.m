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

    if isa(lhs, "dpvar") && helper.isZero(lhs, "obj") && isa(rhs, "dpvar")
        chkAddZero(lhs, rhs, "dpvar:InvalidAddition");
        out = rhs;
        return
    end
    if isa(lhs, "dpvar") && isa(rhs, "dpvar") && helper.isZero(rhs, "obj")
        chkAddZero(rhs, lhs, "dpvar:InvalidAddition");
        out = lhs;
        return
    end
    if isa(lhs, "dpvar") && isa(rhs, "dpmat") && helper.isZero(rhs, "obj")
        chkAddZero(rhs, lhs, "dpvar:InvalidAddition");
        out = lhs;
        return
    end
    if isa(lhs, "dpmat") && helper.isZero(lhs, "obj") && isa(rhs, "dpvar")
        chkAddZero(lhs, rhs, "dpvar:InvalidAddition");
        out = rhs;
        return
    end
    if isa(lhs, "dpvar") && helper.isZero(rhs, "add", lhs.MatrixSize)
        out = lhs;
        return
    end
    if isa(rhs, "dpvar") && helper.isZero(lhs, "add", rhs.MatrixSize)
        out = rhs;
        return
    end

    out = binOp(lhs, rhs, @(a, b) a + b, "dpvar:InvalidAddition");
end

function chkAddZero(zeroVal, other, errId)
    if ~isequal(zeroVal.MatrixSize, other.MatrixSize)
        error(errId, "dpvar operand matrix sizes are incompatible for this operation.");
    end
    other.mergeGrid("dpvar:MixedGrid", zeroVal, other);
end
