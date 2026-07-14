function out = minus(lhs, rhs)
    %MINUS Subtract pdvar affine coefficient expressions.
    %
    %   Syntax:
    %     C = P - Q
    %     C = P - M
    %     C = M - P
    %
    %   Example:
    %     P = pdvar(2, {[0 1]});
    %     C = eye(2) - P;

    if isa(lhs, "pdvar") && isa(rhs, "pdvar") && helper.isZero(rhs, "obj")
        chkAddZero(rhs, lhs, "pdvar:InvalidSubtraction");
        out = lhs;
        return
    end
    if isa(lhs, "pdvar") && isa(rhs, "pdmat") && helper.isZero(rhs, "obj")
        chkAddZero(rhs, lhs, "pdvar:InvalidSubtraction");
        out = lhs;
        return
    end
    if isa(lhs, "pdvar") && helper.isZero(rhs, "add", lhs.MatrixSize)
        out = lhs;
        return
    end
    if isa(lhs, "pdvar") && isa(rhs, "pdvar") && isequal(lhs, rhs)
        out = zeroObj(lhs.GridInfo.Vectors, lhs.MatrixSize);
        return
    end

    out = binOp(lhs, rhs, @(a, b) a - b, "pdvar:InvalidSubtraction");
end

function chkAddZero(zeroVal, other, errId)
    if ~isequal(zeroVal.MatrixSize, other.MatrixSize)
        error(errId, "pdvar operand matrix sizes are incompatible for this operation.");
    end
    other.mergeGrid("pdvar:MixedGrid", zeroVal, other);
end
