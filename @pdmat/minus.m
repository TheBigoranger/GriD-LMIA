function out = minus(lhs, rhs)
    %MINUS Subtract coefficient-backed pdmat objects and numeric constants.
    %
    %   Syntax:
    %     C = A - B
    %     C = A - M
    %     C = M - A
    %
    %   Output:
    %     C - Coefficient-backed pdmat difference after grid and degree
    %         alignment.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     C = 5 - A;

    % Zero and cancellation shortcuts cannot supply missing coefficient evidence.
    if (isa(lhs, "pdmat") && lhs.SourceSummary == "function") || ...
            (isa(rhs, "pdmat") && rhs.SourceSummary == "function")
        error("pdmat:FunctionOnlyAlgebra", ...
            "Function-backed pdmat objects need explicit Bernstein coefficient evidence for this operation.");
    end

    if isa(lhs, "pdmat") && isa(rhs, "pdmat") && ...
            helper.isZero(rhs, "obj") && ...
            lhs.NumRateRows == 0 && rhs.NumRateRows == 0
        if ~isequal(rhs.MatrixSize, lhs.MatrixSize)
            error("pdmat:InvalidSubtraction", ...
                "pdmat matrix sizes are incompatible for this operation.");
        end

        rb = rhs.pickRateBounds("pdmat:InvalidSubtraction", rhs, lhs);
        grid = rhs.mergeGrid("pdmat:MixedGrid", rhs, lhs);
        % A finer zero grid or changed rate bounds must reach knownBinOp.
        if isequal(grid, lhs.GridInfo.Vectors) && isequal(rb, lhs.RateBounds)
            out = lhs;
            return
        end
    end

    if isa(lhs, "pdmat") && helper.isZero(rhs, "add", lhs.MatrixSize)
        out = lhs;
        return
    end

    out = knownBinOp(lhs, rhs, @(a, b) a - b, "pdmat:InvalidSubtraction");
end
