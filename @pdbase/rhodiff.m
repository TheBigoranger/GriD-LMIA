function out = rhodiff(obj, rb)
    %RHODIFF Cell-wise rate-weighted derivative of gridded coefficients.
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
    %   Differentiation is cell-wise. Tensor partials are elevated before
    %   summation. Each rate row takes componentwise minima over its nonzero
    %   partial contributions, then the rows are combined the same way.
    %   Only a differentiated, globally nonzero direction loses one order;
    %   tangential orders and Inf are preserved, with a floor of -1.
    %   Function-only pdmat inputs and existing rate rows are rejected.

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
    rateMap = [];
    if nPar > 1
        for dim = find(deg > 0)
            partDeg = deg;
            partDeg(dim) = partDeg(dim) - 1;
            [~, plans{dim}] = pdbase.elevRow({}, partDeg, outDeg);
        end
        if obj.ContainsDecision && any(deg > 0)
            % Partial blocks are ordered by direction, then coefficient. The
            % same numeric map combines every cell without retaining decisions.
            rateMap = kron(sparse(verts(:, deg > 0)'), ...
                speye(prod(outDeg + 1) * obj.MatrixSize(2)));
        end
    end

    nCell = obj.GridInfo.NumNodes - 1;
    firstCell = true;
    vals = helper.mkNest(nCell, @mkCell);
    hasDec = obj.ContainsDecision && any(deg > 0);
    continuity = diffContinuity(obj, verts, deg, vals);
    out = obj.mkRhodiff(outDeg, vals, rb, hasDec, size(verts, 1), ...
        continuity);

    function coeffs = mkCell(subs)
        % Capture expanded elevation kernels once, then share only numeric
        % plans across cells; every cell still computes its own partials.
        if firstCell
            [coeffs, plans] = diffCell(obj, subs, verts, outDeg, plans, rateMap);
            firstCell = false;
        else
            coeffs = diffCell(obj, subs, verts, outDeg, plans, rateMap);
        end
    end
end

function continuity = diffContinuity(obj, verts, degree, vals)
    %DIFFCONTINUITY Combine bounds from nonzero rate-weighted partials.
    nPar = numel(degree);
    if helper.isZero(vals, "vals")
        continuity = inf(1, nPar);
        return
    end
    continuity = inf(1, nPar);
    activeDims = find(degree > 0);
    zeroPartial = zeroPartials(obj, degree);
    for row = 1:size(verts, 1)
        rowContinuity = inf(1, nPar);
        for dim = activeDims
            if verts(row, dim) == 0 || zeroPartial(dim)
                continue
            end
            partialContinuity = obj.Continuity;
            if ~isinf(partialContinuity(dim))
                partialContinuity(dim) = max(partialContinuity(dim) - 1, -1);
            end
            rowContinuity = min(rowContinuity, partialContinuity);
        end
        continuity = min(continuity, rowContinuity);
    end
end

function tf = zeroPartials(obj, degree)
    %ZEROPARTIALS Prove coefficient-wise zero partials over the full grid.
    nPar = numel(degree);
    tf = false(size(degree));
    cells = obj.cells();
    mult = fliplr(cumprod([1, fliplr(degree(2:end) + 1)]));
    for dim = find(degree > 0 & ~tf)
        tf(dim) = true;
        partDegree = degree;
        partDegree(dim) = partDegree(dim) - 1;
        labels = helper.combRows(arrayfun(@(d) 0:d, partDegree, ...
            "UniformOutput", false));
        for cellIdx = 1:size(cells, 1)
            coeffs = helper.cellGet(obj.LocalValues, cells(cellIdx, :));
            for labelIdx = 1:size(labels, 1)
                label = labels(labelIdx, :);
                next = label;
                next(dim) = next(dim) + 1;
                lhs = coeffs{sum(label .* mult) + 1};
                rhs = coeffs{sum(next .* mult) + 1};
                if ~samePartialCoeff(lhs, rhs)
                    tf(dim) = false;
                    break
                end
            end
            if ~tf(dim)
                break
            end
        end
    end
end

function tf = samePartialCoeff(lhs, rhs)
    %SAMEPARTIALCOEFF Prove a zero forward difference in one direction.
    tf = helper.isZero(rhs - lhs, "vals");
end

function [coeffs, plans] = diffCell(obj, subs, verts, outDeg, plans, rateMap)
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
    [partials, plans] = tensorPartials(vals, deg, h, activeDims, plans);
    if obj.ContainsDecision
        blocks = [partials{activeDims}];
        packed = horzcat(blocks{:}) * rateMap;
        width = obj.MatrixSize(2);
        for row = 1:nVert
            for k = 1:nOut
                cols = ((row - 1) * nOut + k - 1) * width + (1:width);
                coeffs{row, k} = packed(:, cols);
            end
        end
        return
    end
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

function [partials, plans] = tensorPartials(vals, deg, h, activeDims, plans)
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
        if plans{dim}.Columns == 0
            [partials{dim}, plans{dim}] = pdbase.elevRow( ...
                part, partDeg, deg, plans{dim});
        else
            partials{dim} = pdbase.elevRow(part, partDeg, deg, plans{dim});
        end
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
