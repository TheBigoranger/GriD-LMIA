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

    if isa(lhs, "pdvar") && (isa(rhs, "pdvar") || isa(rhs, "pdmat")) && ...
            helper.isZero(rhs, "obj") && ...
            ~lhs.HasRateDependence && ~rhs.HasRateDependence
        % The identity fast path must still enforce ordinary subtraction compatibility.
        if ~isequal(rhs.MatrixSize, lhs.MatrixSize)
            error("pdvar:InvalidSubtraction", ...
                "pdvar operand matrix sizes are incompatible for this operation.");
        end
        lhs.mergeGrid("pdvar:MixedGrid", rhs, lhs);
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
