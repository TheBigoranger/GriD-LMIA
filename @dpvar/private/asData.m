function data = asData(grid, val, reqSize, rb, errId)
    %ASDATA Convert supported operands to dpvar data on the target grid.

    info = helper.mkGrid(grid, "dpvar");

    if isa(val, "dpvar")
        if ~isempty(val.RateBounds) && (isempty(rb) || ~isequal(rb, val.RateBounds))
            error(errId, "dpvar operands must have matching RateBounds.");
        end
        % Empty operand metadata inherits the operation-level bounds picked
        % from the other dpvar input.
        if ~isempty(reqSize) && ~isequal(val.MatrixSize, reqSize)
            error(errId, "dpvar operand matrix sizes are incompatible for this operation.");
        end
        nCoeff = (val.Degree + 1) ^ val.npar();
        hasRows = isRateRows(val.LocalValues, val.GridInfo.Vectors, nCoeff);
        same = sameGrid(info, val, errId);
        if same
            vals = val.LocalValues;
        elseif hasRows
            error(errId, ...
                "Rate-vertex dpvar expressions require matching grids in this operation.");
        else
            % Same-bound refinement only takes Bernstein point samples and
            % recombines them linearly, preserving affine YALMIP structure.
            vals = fitVals(info, val.Degree, val.MatrixSize, @(pt) evalDpvar(val, pt));
        end
        data = pack(val.MatrixSize, val.Degree, vals, ...
            val.ContainsDecision, val.HasRateDependence, val.IsContinuous, hasRows);
        return
    end

    if isa(val, "dpmat")
        if val.SourceSummary == "function"
            error("dpvar:FunctionOnlyAlgebra", ...
                "Function-backed dpmat objects need explicit Bernstein coefficient evidence for dpvar algebra.");
        end
        if ~isempty(reqSize) && ~isequal(val.MatrixSize, reqSize)
            error(errId, "dpvar operand matrix sizes are incompatible for this operation.");
        end
        if sameGrid(info, val, errId)
            vals = val.LocalValues;
        else
            % Coefficient-backed known data is re-expressed on the same
            % common refinement before entering symbolic dpvar algebra.
            vals = fitVals(info, val.Degree, val.MatrixSize, @(pt) evaluate(val, pt));
        end
        data = pack(val.MatrixSize, val.Degree, vals, false, ...
            val.HasRateDependence, val.IsContinuous, false);
        return
    end

    mat = chkMat(val, reqSize, errId);
    data = pack(size(mat), 0, helper.mkNest(info.NumNodes - 1, @(~) {mat}), ...
        isa(mat, "sdpvar"), false, true, false);
end

function data = pack(sz, deg, vals, hasDec, hasRate, isCont, hasRows)
    data.MatrixSize = sz;
    data.Degree = deg;
    data.LocalValues = vals;
    data.ContainsDecision = hasDec;
    data.HasRateDependence = hasRate;
    data.IsContinuous = isCont;
    data.HasRateRows = hasRows;
end

function tf = sameGrid(info, val, errId)
    if numel(info.Vectors) ~= val.npar()
        error(errId, "dpvar operands must use the same parameter dimension.");
    end
    tf = true;
    for k = 1:numel(info.Vectors)
        tf = tf && isequal(info.Vectors{k}, val.GridInfo.Vectors{k});
    end
end

function val = evalDpvar(obj, pt)
    [subs, alpha] = localPoint(obj, pt);
    coeffs = obj.coeffs(subs);
    lbls = obj.lbls();
    val = zeros(obj.MatrixSize);
    for k = 1:numel(coeffs)
        w = 1;
        for p = 1:numel(alpha)
            j = lbls(k, p);
            w = w * nchoosek(obj.Degree, j) * ...
                alpha(p)^(obj.Degree - j) * (1 - alpha(p))^j;
        end
        val = val + coeffs{k} .* w;
    end
end

function [subs, alpha] = localPoint(obj, pt)
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
        alpha(p) = (hi - x) / (hi - lo);
    end
end

function mat = chkMat(val, reqSize, errId)
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
        "Numeric operands must be nonempty finite real matrices.", ...
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
