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

    if isa(lhs, "dpmat") && isa(rhs, "dpmat") && helper.isZero(rhs, "obj")
        if ~isequal(rhs.MatrixSize, lhs.MatrixSize)
            error("dpmat:InvalidSubtraction", ...
                "dpmat matrix sizes are incompatible for this operation.");
        end

        rhs.mergeGrid("dpmat:MixedGrid", rhs, lhs);
        out = lhs;
        return
    end

    if isa(lhs, "dpmat") && helper.isZero(rhs, "add", lhs.MatrixSize)
        out = lhs;
        return
    end

    if isa(lhs, "dpmat") && isa(rhs, "dpmat") && isequal(lhs, rhs)
        out = zeroObj(lhs.GridInfo.Vectors, lhs.MatrixSize);
        return
    end

    out = binOp(lhs, rhs, @(a, b) a - b, "dpmat:InvalidSubtraction");
end
