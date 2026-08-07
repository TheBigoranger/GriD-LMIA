function out = rhodiff(obj, rb)
    %RHODIFF Cell-local rate-weighted derivative of gridded coefficients.
    %
    %   Syntax:
    %     D = rhodiff(A, rb)
    %     D = rhodiff(A)
    %
    %   Arguments:
    %     A  - Coefficient-backed pdbase, pdmat, or pdvar object.
    %     rb - Optional ell-by-2 rate box; otherwise A.RateBounds.
    %
    %   Output:
    %     D - Same dynamic class as A, with one row per rate-box vertex.
    %
    %   Example:
    %     A = pdmat([0 1], {0, 1}, Degree=1, RateBounds=[-1 1]);
    %     D = rhodiff(A);
    %
    %   Differentiation is cell-local. Tensor partials are elevated before
    %   summation, and the output is deliberately discontinuous. Function-only
    %   pdmat inputs and objects that already contain rate rows are rejected.

    prefix = string(class(obj));
    if nargin > 2
        error(prefix + ":InvalidDiff", ...
            "rhodiff supports only rhodiff(A) and rhodiff(A, RateBounds).");
    end
    if obj.SourceSummary == "function"
        error(prefix + ":FunctionOnlyDiff", ...
            "Function-only objects require Bernstein coefficient evidence before rhodiff.");
    end
    if obj.NumRateRows ~= 0
        error(prefix + ":InvalidDiff", ...
            "rhodiff of existing rate-vertex coefficient rows is unsupported.");
    end

    nPar = obj.npar();
    if nargin < 2
        if isempty(obj.RateBounds)
            error(prefix + ":MissingRateBounds", ...
                "rhodiff(A) requires A to carry nonempty RateBounds.");
        end
        rb = obj.RateBounds;
    else
        rb = double(helper.chk(rb, prefix + ":InvalidRateBounds", ...
            "RateBounds", ...
            "numeric", "real", "finite", "rowbounds", "Size", [nPar, 2]));
        if ~isempty(obj.RateBounds) && ~isequal(rb, obj.RateBounds)
            error(prefix + ":RateBoundsMismatch", ...
                "Explicit RateBounds must match stored RateBounds when both are present.");
        end
    end

    verts = helper.rateVerts(rb);
    deg = obj.Degree;
    if nPar == 1
        outDeg = max(deg - 1, 0);
    else
        outDeg = deg;
    end
    plans = cell(1, nPar);
    if nPar > 1
        for dim = find(deg > 0)
            partDeg = deg;
            partDeg(dim) = partDeg(dim) - 1;
            [~, plans{dim}] = pdbase.elevRow({}, partDeg, outDeg);
        end
    end

    nCell = obj.GridInfo.NumNodes - 1;
    vals = helper.mkNest(nCell, ...
        @(subs) diffCell(obj, subs, verts, outDeg, plans));
    hasDec = obj.ContainsDecision && any(deg > 0);
    out = obj.mkRhodiff(outDeg, vals, rb, hasDec, size(verts, 1));
end

function coeffs = diffCell(obj, subs, verts, outDeg, plans)
    %DIFFCELL Build all rate-vertex derivative rows for one physical cell.
    deg = obj.Degree;
    nPar = obj.npar();
    nVert = size(verts, 1);
    nOut = prod(outDeg + 1);
    if all(deg == 0)
        coeffs = repmat({zeros(obj.MatrixSize)}, nVert, nOut);
        return
    end

    vals = helper.cellGet(obj.LocalValues, subs);
    h = zeros(1, nPar);
    for k = 1:nPar
        grid = obj.GridInfo.Vectors{k};
        h(k) = grid(subs(k) + 1) - grid(subs(k));
    end

    coeffs = cell(nVert, nOut);
    if nPar == 1
        for row = 1:nVert
            coeffs(row, :) = scalarDiff(vals, deg(1), h(1), ...
                verts(row, 1));
        end
        return
    end

    % Tensor partials do not depend on the selected rate vertex. Compute and
    % elevate each active direction once, then reuse those affine expressions.
    activeDims = find(deg > 0);
    partials = tensorPartials(vals, deg, h, activeDims, plans);
    for row = 1:nVert
        coeffs(row, :) = combinePartials(partials, activeDims, ...
            verts(row, :), obj.MatrixSize, nOut);
    end
end

function row = scalarDiff(vals, deg, h, rate)
    %SCALARDIFF Differentiate one scalar-parameter Bernstein coefficient row.
    row = cell(1, deg);
    scale = deg * rate / h;
    for q = 0:(deg - 1)
        row{q + 1} = (vals{q + 2} - vals{q + 1}) .* scale;
    end
end

function partials = tensorPartials(vals, deg, h, activeDims, plans)
    %TENSORPARTIALS Differentiate and elevate each active tensor direction.
    partials = cell(1, numel(deg));
    % Map tensor labels to repository flat positions in combRows order.
    mult = fliplr(cumprod([1, fliplr(deg(2:end) + 1)]));

    for dim = activeDims
        partDeg = deg;
        partDeg(dim) = partDeg(dim) - 1;
        vecs = arrayfun(@(oneDeg) 0:oneDeg, partDeg, ...
            "UniformOutput", false);
        partLbls = helper.combRows(vecs);
        part = cell(1, size(partLbls, 1));
        for k = 1:size(partLbls, 1)
            lbl = partLbls(k, :);
            nxt = lbl;
            nxt(dim) = nxt(dim) + 1;
            part{k} = (vals{sum(nxt .* mult) + 1} - ...
                vals{sum(lbl .* mult) + 1}) .* ...
                (deg(dim) / h(dim));
        end

        % Each partial has one reduced axis. Elevating it independently before
        % applying the rate vertex keeps all directions in one tensor basis.
        partials{dim} = pdbase.elevRow(part, partDeg, deg, plans{dim});
    end
end

function row = combinePartials(partials, activeDims, rate, sz, nOut)
    %COMBINEPARTIALS Apply one rate vertex in the established addition order.
    row = repmat({zeros(sz)}, 1, nOut);
    for dim = activeDims
        elevated = partials{dim};
        for k = 1:numel(row)
            row{k} = row{k} + elevated{k} .* rate(dim);
        end
    end
end
