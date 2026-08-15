function out = fromKnownProduct(lhs, rhs)
    %FROMKNOWNPRODUCT Build a pdvar from one affine pdmat/sdpvar product.
    %
    %   This class-restricted bridge is called by pdmat.mtimes after MATLAB
    %   dispatches either pdmat/sdpvar operand order through pdmat. It keeps
    %   the symbolic factor at Degree zero and preserves matrix-product order.

    if isa(lhs, "pdmat") && isa(rhs, "sdpvar")
        known = lhs;
        sym = rhs;
        knownLeft = true;
    elseif isa(lhs, "sdpvar") && isa(rhs, "pdmat")
        known = rhs;
        sym = lhs;
        knownLeft = false;
    else
        error("pdmat:InvalidMultiplication", ...
            "Mixed symbolic products require one pdmat and one sdpvar operand.");
    end

    if known.SourceSummary == "function"
        error("pdmat:FunctionOnlyAlgebra", ...
            "Function-backed pdmat objects need explicit Bernstein coefficient evidence for multiplication.");
    end
    if ~ismatrix(sym) || ~isreal(sym) || ~islinear(sym)
        error("pdmat:InvalidMultiplication", ...
            "sdpvar operands must be affine real 2-D matrices.");
    end

    if knownLeft
        leftSz = known.MatrixSize;
        rightSz = size(sym);
    else
        leftSz = size(sym);
        rightSz = known.MatrixSize;
    end

    % Match the package's scalar-aware mtimes contract before zero shortcuts.
    if isequal(leftSz, [1 1])
        sz = rightSz;
    elseif isequal(rightSz, [1 1])
        sz = leftSz;
    elseif leftSz(2) ~= rightSz(1)
        error("pdmat:InvalidMultiplication", ...
            "Inner matrix dimensions must agree for mixed pdmat/sdpvar multiplication.");
    else
        sz = [leftSz(1), rightSz(2)];
    end
    if helper.isZero(known, "obj")
        % Clear symbolic and rate metadata only after all public operand
        % validation has established the output shape and rate contract.
        out = zeroObj(known.GridInfo.Vectors, sz);
        return
    end
    if knownLeft
        fcn = @(a) a * sym;
    else
        fcn = @(a) sym * a;
    end

    % A bare sdpvar is parameter-independent, so mapping the existing
    % coefficient tree is exactly Degree + 0 Bernstein multiplication.
    vals = pdbase.mapVals(known.LocalValues, fcn, known.GridInfo.Vectors);
    out = pdvar(mkCtorState(known.GridInfo.Vectors, sz, known.Degree, vals, ...
        true, known.RateBounds, "expression", known.IsContinuous, ...
        "fast", known.NumRateRows));
end
