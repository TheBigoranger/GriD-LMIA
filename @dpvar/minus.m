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

    if isa(lhs, "dpvar") && isa(rhs, "dpvar") && isZeroObj(rhs)
        chkAddZero(rhs, lhs, "dpvar:InvalidSubtraction");
        out = lhs;
        return
    end
    if isa(lhs, "dpvar") && isZeroKnown(rhs)
        chkAddZero(rhs, lhs, "dpvar:InvalidSubtraction");
        out = lhs;
        return
    end
    if isa(lhs, "dpvar") && isZeroAdd(rhs, lhs.MatrixSize)
        out = lhs;
        return
    end
    if isa(lhs, "dpvar") && isa(rhs, "dpvar") && isequal(lhs, rhs)
        out = zeroObj(lhs.GridInfo.Vectors, lhs.MatrixSize);
        return
    end

    out = binOp(lhs, rhs, @(a, b) a - b, "dpvar:InvalidSubtraction");
end

function chkAddZero(zeroVal, other, errId)
    if ~isequal(zeroVal.MatrixSize, other.MatrixSize)
        error(errId, "dpvar operand matrix sizes are incompatible for this operation.");
    end
    other.mergeGrid("dpvar:MixedGrid", zeroVal, other);
end
