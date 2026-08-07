function data = normOperand(grid, val, reqSize, rb, errId)
    %NORMOPERAND Normalize supported operands on the target grid.
    %
    %   Syntax:
    %     data = normOperand(grid, val, reqSize, rb, errId)
    %
    %   Arguments:
    %     grid    - Target common-refinement grid.
    %     val     - pdvar, pdmat, numeric, or affine sdpvar operand.
    %     reqSize - Required matrix size, or empty to infer it.
    %     rb      - Operation-level RateBounds, possibly empty.
    %     errId   - Operation-specific validation identifier.
    %
    %   Output:
    %     data - Normalized coefficient tree and decision/rate metadata.
    %
    %   Example (via public algebra):
    %     P = pdvar(1, {[0 1]});
    %     C = P + 1;
    %
    %   VAL may be a pdvar, coefficient-backed pdmat, numeric matrix, or
    %   affine real sdpvar. The returned struct carries matrix size, degree,
    %   LocalValues, decision/rate metadata, and whether rate rows are stored.
    %   Function-only pdmat objects, incompatible sizes/bounds, nonlinear
    %   sdpvar values, and rate-row grid changes fail with package-specific
    %   errors; ordinary operand validation uses ERRID.

    info = helper.mkGrid(grid, "pdvar");

    if isa(val, "pdvar")
        if ~isempty(val.RateBounds) && (isempty(rb) || ~isequal(rb, val.RateBounds))
            error(errId, "pdvar operands must have matching RateBounds.");
        end
        % Empty operand metadata inherits the operation-level bounds picked
        % from the other pdvar input.
        if ~isempty(reqSize) && ~isequal(val.MatrixSize, reqSize)
            error(errId, "pdvar operand matrix sizes are incompatible for this operation.");
        end
        numRateRows = val.NumRateRows;
        same = sameGrid(info, val, errId);
        if same
            vals = val.LocalValues;
        elseif numRateRows ~= 0
            error(errId, ...
                "Rate-vertex pdvar expressions require matching grids in this operation.");
        else
            % Same-bound refinement only takes Bernstein point samples and
            % recombines them linearly, preserving affine YALMIP structure.
            vals = helper.fitVals(info, val.Degree, val.MatrixSize, ...
                @(pt) evalPdvar(val, pt), "pdvar");
        end
        data = pack(val.MatrixSize, val.Degree, vals, ...
            val.ContainsDecision, val.IsContinuous, numRateRows);
        return
    end

    if isa(val, "pdmat")
        if val.SourceSummary == "function"
            error("pdvar:FunctionOnlyAlgebra", ...
                "Function-backed pdmat objects need explicit Bernstein coefficient evidence for pdvar algebra.");
        end
        if ~isempty(reqSize) && ~isequal(val.MatrixSize, reqSize)
            error(errId, "pdvar operand matrix sizes are incompatible for this operation.");
        end
        if ~isempty(val.RateBounds) && ...
                (isempty(rb) || ~isequal(rb, val.RateBounds))
            error(errId, "Gridded operands must have matching RateBounds.");
        end
        numRateRows = val.NumRateRows;
        if sameGrid(info, val, errId)
            vals = val.LocalValues;
        elseif numRateRows ~= 0
            error(errId, ...
                "Rate-vertex pdmat expressions require matching grids in pdvar algebra.");
        else
            % Coefficient-backed known data is re-expressed on the same
            % common refinement before entering symbolic pdvar algebra.
            vals = helper.fitVals(info, val.Degree, val.MatrixSize, ...
                @(pt) evaluate(val, pt), "pdvar");
        end
        data = pack(val.MatrixSize, val.Degree, vals, false, ...
            val.IsContinuous, numRateRows);
        return
    end

    mat = chkMat(val, reqSize, errId);
    data = pack(size(mat), zeros(1, numel(grid)), ...
        helper.mkNest(info.NumNodes - 1, @(~) {mat}), ...
        isa(mat, "sdpvar"), true, 0);
end

function data = pack(sz, deg, vals, hasDec, isCont, numRateRows)
    %PACK Keep the metadata fields consumed by the pdvar constructor together.
    %   NUMRATEROWS distinguishes ordinary coefficient leaves from rate-vertex
    %   tables; the distinction is needed by later degree and row operations.
    data.MatrixSize = sz;
    data.Degree = deg;
    data.LocalValues = vals;
    data.ContainsDecision = hasDec;
    data.IsContinuous = isCont;
    data.NumRateRows = numRateRows;
end

function tf = sameGrid(info, val, errId)
    %SAMEGRID Compare parameter vectors and reject dimension mismatches.
    %   A false result means refinement is still possible for ordinary
    %   coefficient data; rate-row data is rejected by the caller because its
    %   vertex-row alignment cannot be inferred across different grids.
    if numel(info.Vectors) ~= val.npar()
        error(errId, "pdvar operands must use the same parameter dimension.");
    end
    tf = true;
    for k = 1:numel(info.Vectors)
        tf = tf && isequal(info.Vectors{k}, val.GridInfo.Vectors{k});
    end
end

function val = evalPdvar(obj, pt)
    %EVALPDVAR Reconstruct one pdvar expression at a physical point.
    %   This sampling path is used only to refit ordinary coefficient data on
    %   a common refinement grid; it preserves affine YALMIP expressions.
    [subs, alpha] = localPoint(obj, pt);
    coeffs = obj.coeffs(subs);
    lbls = obj.lbls();
    val = zeros(obj.MatrixSize);
    for k = 1:numel(coeffs)
        w = 1;
        for p = 1:numel(alpha)
            j = lbls(k, p);
            deg = obj.Degree(p);
            w = w * nchoosek(deg, j) * ...
                (1 - alpha(p))^(deg - j) * alpha(p)^j;
        end
        val = val + coeffs{k} .* w;
    end
end

function [subs, alpha] = localPoint(obj, pt)
    %LOCALPOINT Map a physical point to its cell and Bernstein coordinates.
    %   alpha=(rho-lo)/(hi-lo) is 0 at the lower face and 1 at the upper
    %   face of each cell, matching repository endpoint labels.
    nPar = obj.npar();
    subs = zeros(1, nPar);
    alpha = zeros(1, nPar);
    for p = 1:nPar
        v = obj.GridInfo.Vectors{p};
        x = pt(p);
        if x == v(end)
            subs(p) = numel(v) - 1;
        else
            subs(p) = find(v <= x, 1, "last");
        end

        lo = v(subs(p));
        hi = v(subs(p) + 1);
        alpha(p) = (x - lo) / (hi - lo);
    end
end

function mat = chkMat(val, reqSize, errId)
    %CHKMat Validate an affine sdpvar or numeric matrix operand.
    %   Numeric scalars are expanded to REQSIZE; other numeric shapes must
    %   already match. Nonlinear, complex, or incompatible sdpvar operands
    %   are rejected with ERRID.
    if isa(val, "sdpvar")
        if ~ismatrix(val) || ~isreal(val) || ~islinear(val)
            error(errId, "sdpvar operands must be affine real 2-D matrices with compatible size.");
        end
        if ~isempty(reqSize) && ~isequal(size(val), reqSize)
            error(errId, "sdpvar operands must be affine real 2-D matrices with compatible size.");
        end
        mat = val;
        return
    end

    helper.chk(val, errId, ...
        "numeric operand", ...
        "numeric", "real", "finite", "matrix", "nonempty");
    if isempty(reqSize)
        mat = val;
    elseif isscalar(val)
        mat = repmat(val, reqSize);
    elseif isequal(size(val), reqSize)
        mat = val;
    else
        error(errId, "Numeric operand size is incompatible for this operation.");
    end
end
