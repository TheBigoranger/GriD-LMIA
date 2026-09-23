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
            vals = helper.refineVals(info, val);
        end
        data = pack(val.MatrixSize, val.Degree, vals, ...
            val.ContainsDecision, val.Continuity, numRateRows);
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
            vals = helper.refineVals(info, val);
        end
        data = pack(val.MatrixSize, val.Degree, vals, false, ...
            val.Continuity, numRateRows);
        return
    end

    mat = chkMat(val, reqSize, errId);
    data = pack(size(mat), zeros(1, numel(grid)), ...
        helper.mkNest(info.NumNodes - 1, @(~) {mat}), ...
        isa(mat, "sdpvar"), inf(1, numel(grid)), 0);
end

function data = pack(sz, deg, vals, hasDec, continuity, numRateRows)
    %PACK Keep the metadata fields consumed by the pdvar constructor together.
    %   NUMRATEROWS distinguishes ordinary coefficient leaves from rate-vertex
    %   tables; the distinction is needed by later degree and row operations.
    data.MatrixSize = sz;
    data.Degree = deg;
    data.LocalValues = vals;
    data.ContainsDecision = hasDec;
    data.Continuity = continuity;
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
