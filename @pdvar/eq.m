function out = eq(lhs, rhs)
    %EQ Assemble an exact coefficient equality for pdvar expressions.
    %
    %   Syntax:
    %     C = P == Q
    %     C = P == M
    %
    %   Output:
    %     C - pdlmi wrapper containing exact, direct coefficient equalities.
    %
    %   Ordinary pdvar expressions use the same numeric, affine sdpvar,
    %   coefficient-backed pdmat, grid, and degree promotion as subtraction.
    %   Rectangular and non-Hermitian residuals are valid without an inequality
    %   warning. A derivative-row expression may be equated only to another
    %   derivative-row pdvar; a row-kind mismatch raises
    %   pdvar:InvalidEqualityRows before subtraction reports any incompatible
    %   grid, degree, RateBounds, shape, or affine metadata. Equality is
    %   direct-only, so certificate selection raises
    %   pdlmi:UnsupportedEqualityCertificate. A proven identity may contain no
    %   stored constraints, in which case C.toYalmip() returns [].
    %
    %   Example:
    %     P = pdvar(2, {[0 1]});
    %     C = P == eye(2);

    lhsKind = rowKind(lhs);
    rhsKind = rowKind(rhs);
    if lhsKind ~= rhsKind
        error("pdvar:InvalidEqualityRows", ...
            "A derivative-row pdvar may equal only another derivative-row pdvar.");
    end

    % Subtraction owns operand promotion, compatible-grid refinement, and
    % degree/rate alignment before coefficient equality is assembled.
    out = pdlmi(lhs - rhs, "==");
end

function kind = rowKind(val)
    %ROWKIND Require one consistent ordinary or derivative row kind.

    kind = "ordinary";
    if ~isa(val, "pdvar")
        return
    end

    kind = "";
    cells = val.cells();
    for k = 1:size(cells, 1)
        coeffs = val.coeffs(cells(k, :));
        cellKind = "ordinary";
        if size(coeffs, 1) > 1
            cellKind = "derivative";
        end
        if kind == ""
            kind = cellKind;
        elseif kind ~= cellKind
            error("pdvar:InvalidEqualityRows", ...
                "A pdvar equality operand cannot mix ordinary and derivative rows across cells.");
        end
    end
end
