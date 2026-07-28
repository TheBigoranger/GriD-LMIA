function out = minus(lhs, rhs)
    %MINUS Subtract coefficient-backed pdmat objects and numeric constants.
    %
    %   Syntax:
    %     C = A - B
    %     C = A - M
    %     C = M - A
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     C = 5 - A;

    if isa(lhs, "pdmat") && isa(rhs, "pdmat") && ...
            helper.isZero(rhs, "obj") && ...
            ~lhs.hasRateRows() && ~rhs.hasRateRows()
        if ~isequal(rhs.MatrixSize, lhs.MatrixSize)
            error("pdmat:InvalidSubtraction", ...
                "pdmat matrix sizes are incompatible for this operation.");
        end

        rhs.pickRateBounds("pdmat:InvalidSubtraction", rhs, lhs);
        rhs.mergeGrid("pdmat:MixedGrid", rhs, lhs);
        out = lhs;
        return
    end

    if isa(lhs, "pdmat") && helper.isZero(rhs, "add", lhs.MatrixSize)
        out = lhs;
        return
    end

    if isa(lhs, "pdmat") && isa(rhs, "pdmat") && isequal(lhs, rhs)
        out = zeroObj(lhs.GridInfo.Vectors, lhs.MatrixSize);
        return
    end

    out = binOp(lhs, rhs, @(a, b) a - b, "pdmat:InvalidSubtraction");
end
