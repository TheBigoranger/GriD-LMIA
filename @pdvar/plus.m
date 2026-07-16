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

    zeroVal = [];
    if isa(lhs, "pdvar") && isa(rhs, "pdvar")
        if helper.isZero(lhs, "obj")
            zeroVal = lhs;
            out = rhs;
        elseif helper.isZero(rhs, "obj")
            zeroVal = rhs;
            out = lhs;
        end
    elseif isa(lhs, "pdvar") && isa(rhs, "pdmat") && helper.isZero(rhs, "obj")
        zeroVal = rhs;
        out = lhs;
    elseif isa(lhs, "pdmat") && isa(rhs, "pdvar") && helper.isZero(lhs, "obj")
        zeroVal = lhs;
        out = rhs;
    end

    % The identity fast path must still enforce ordinary addition compatibility.
    if ~isempty(zeroVal)
        if ~isequal(zeroVal.MatrixSize, out.MatrixSize)
            error("pdvar:InvalidAddition", ...
                "pdvar operand matrix sizes are incompatible for this operation.");
        end
        out.mergeGrid("pdvar:MixedGrid", zeroVal, out);
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
