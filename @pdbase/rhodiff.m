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
    if obj.hasRateRows()
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
            "RateBounds must be a finite ell-by-2 matrix with lower <= upper.", ...
            "numeric", "real", "finite", "rowbounds", "Size", [nPar, 2]));
        if ~isempty(obj.RateBounds) && ~isequal(rb, obj.RateBounds)
            error(prefix + ":RateBoundsMismatch", ...
                "Explicit RateBounds must match stored RateBounds when both are present.");
        end
    end

    % combRows supplies the same deterministic order used throughout storage.
    verts = helper.combRows(num2cell(rb, 2).');
    deg = obj.Degree;
    if deg == 0 || nPar == 1
        outDeg = max(deg - 1, 0);
    else
        outDeg = deg;
    end

    nCell = obj.GridInfo.NumNodes - 1;
    vals = helper.mkNest(nCell, ...
        @(subs) diffCell(obj, subs, verts, outDeg));
    hasDec = obj.ContainsDecision && deg > 0;
    out = obj.mkRhodiff(outDeg, vals, rb, hasDec);
end

function coeffs = diffCell(obj, subs, verts, outDeg)
    %DIFFCELL Build all rate-vertex derivative rows for one physical cell.
    deg = obj.Degree;
    nPar = obj.npar();
    nVert = size(verts, 1);
    nOut = (outDeg + 1) ^ nPar;
    if deg == 0
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
    for row = 1:nVert
        if nPar == 1
            coeffs(row, :) = scalarDiff(vals, deg, h(1), verts(row, 1));
        else
            coeffs(row, :) = tensorDiff(vals, deg, h, ...
                verts(row, :), obj.MatrixSize);
        end
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

function row = tensorDiff(vals, deg, h, rate, sz)
    %TENSORDIFF Elevate mixed tensor partials into one common degree.
    nPar = numel(h);
    row = cell(1, (deg + 1) ^ nPar);
    mult = (deg + 1) .^ (nPar - 1:-1:0);

    for dim = 1:nPar
        vecs = repmat({0:deg}, 1, nPar);
        vecs{dim} = 0:(deg - 1);
        partLbls = helper.combRows(vecs);
        for k = 1:size(partLbls, 1)
            lbl = partLbls(k, :);
            nxt = lbl;
            nxt(dim) = nxt(dim) + 1;
            base = (vals{sum(nxt .* mult) + 1} - ...
                vals{sum(lbl .* mult) + 1}) .* ...
                (deg * rate(dim) / h(dim));

            for outLabel = lbl(dim):(lbl(dim) + 1)
                out = lbl;
                out(dim) = outLabel;
                idx = sum(out .* mult) + 1;
                scale = nchoosek(deg - 1, lbl(dim)) ...
                    * nchoosek(1, outLabel - lbl(dim)) ...
                    / nchoosek(deg, outLabel);
                term = base .* scale;
                if isempty(row{idx})
                    row{idx} = term;
                else
                    row{idx} = row{idx} + term;
                end
            end
        end
    end

    for k = 1:numel(row)
        if isempty(row{k})
            row{k} = zeros(sz);
        end
    end
end
