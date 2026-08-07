function out = plus(lhs, rhs)
    %PLUS Add coefficient-backed pdmat objects and numeric constants.
    %
    %   Syntax:
    %     C = A + B
    %     C = A + M
    %     C = M + A
    %
    %   Output:
    %     C - Coefficient-backed pdmat sum after grid and degree alignment.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     C = A + 3;

    if isa(lhs, "pdmat") && isa(rhs, "pdmat")
        zeroVal = [];
        if helper.isZero(lhs, "obj")
            zeroVal = lhs;
            out = rhs;
        elseif helper.isZero(rhs, "obj")
            zeroVal = rhs;
            out = lhs;
        end

        % The identity fast path must still enforce ordinary addition compatibility.
        if ~isempty(zeroVal)
            if zeroVal.NumRateRows ~= 0 || out.NumRateRows ~= 0
                zeroVal = [];
            end
        end
        if ~isempty(zeroVal)
            if ~isequal(zeroVal.MatrixSize, out.MatrixSize)
                error("pdmat:InvalidAddition", ...
                    "pdmat matrix sizes are incompatible for this operation.");
            end
            zeroVal.pickRateBounds("pdmat:InvalidAddition", zeroVal, out);
            zeroVal.mergeGrid("pdmat:MixedGrid", zeroVal, out);
            return
        end
    end
    if isa(lhs, "pdmat") && helper.isZero(rhs, "add", lhs.MatrixSize)
        out = lhs;
        return
    end
    if isa(rhs, "pdmat") && helper.isZero(lhs, "add", rhs.MatrixSize)
        out = rhs;
        return
    end

    out = knownBinOp(lhs, rhs, @(a, b) a + b, "pdmat:InvalidAddition");
end
