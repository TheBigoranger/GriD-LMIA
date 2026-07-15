function out = rhodiff(obj, rb)
    %RHODIFF Cell-local rate-weighted derivative of a pdvar expression.
    %
    %   Syntax:
    %     D = rhodiff(P, rb)
    %     D = rhodiff(P)
    %
    %   Arguments:
    %     P  - Ordinary pdvar expression to differentiate cell by cell.
    %     rb - Optional ell-by-2 parameter-rate bounds; otherwise P.RateBounds.
    %
    %   Output:
    %     D - Discontinuous pdvar with one coefficient row per rate vertex.
    %
    %   Example:
    %     P = pdvar(1, {[0 1 2]}, RateBounds=[-1 1]);
    %     D = rhodiff(P);
    %
    %   rhodiff(P, rb) stores one rate-vertex row per physical hypercube.
    %   The derivative is discontinuous at shared cell boundaries because
    %   each hypercube uses its own local Bernstein coefficients.  Without
    %   rb, the nonempty RateBounds carried by P are used.

    if nargin > 2
        error("pdvar:InvalidDiff", ...
            "rhodiff supports only rhodiff(P) and rhodiff(P, RateBounds).");
    end

    nPar = obj.npar();
    nCoeff = (obj.Degree + 1) ^ nPar;
    if isRateRows(obj.LocalValues, obj.GridInfo.Vectors, nCoeff)
        error("pdvar:InvalidDiff", ...
            "rhodiff of an existing rate-vertex pdvar expression is unsupported.");
    end

    if nargin < 2
        if ~obj.HasRateDependence || isempty(obj.RateBounds)
            error("pdvar:MissingRateBounds", ...
                "rhodiff(P) requires P to carry nonempty RateBounds.");
        end
        rb = obj.RateBounds;
    else
        rb = double(helper.chk(rb, "pdvar:InvalidRateBounds", ...
            "RateBounds must be a finite ell-by-2 matrix with lower <= upper.", ...
            "numeric", "real", "finite", "rowbounds", "Size", [nPar, 2]));
        if ~isempty(obj.RateBounds) && ~isequal(rb, obj.RateBounds)
            error("pdvar:RateBoundsMismatch", ...
                "Explicit RateBounds must match P.RateBounds when both are present.");
        end
    end

    % helper.combRows preserves the package-wide lower/upper tensor order.
    verts = helper.combRows(num2cell(rb, 2).');
    deg = obj.Degree;
    if deg == 0 || nPar == 1
        outDeg = max(deg - 1, 0);
    else
        % Multivariate partials have mixed degree.  Store their rate-weighted
        % sum after elevation to the common tensor degree m basis.
        outDeg = deg;
    end

    grid = obj.GridInfo.Vectors;
    nCell = obj.GridInfo.NumNodes - 1;
    vals = helper.mkNest(nCell, @(subs) diffCell(obj, subs, verts, outDeg));
    hasDec = obj.ContainsDecision && deg > 0;
    out = pdvar(mkInit(grid, obj.MatrixSize, outDeg, vals, ...
        hasDec, true, rb, "derivative", false));
end

function coeffs = diffCell(obj, subs, verts, outDeg)
    %DIFFCELL Build every rate-vertex derivative row for one physical cell.
    deg = obj.Degree;
    nPar = obj.npar();
    nVert = size(verts, 1);
    nOut = (outDeg + 1) ^ nPar;
    sz = obj.MatrixSize;
    if deg == 0
        coeffs = cell(nVert, nOut);
        for row = 1:nVert
            for c = 1:nOut
                coeffs{row, c} = zeros(sz);
            end
        end
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
            coeffs(row, :) = tensorDiff(vals, deg, h, verts(row, :), sz);
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
    %TENSORDIFF Elevate and sum all tensor partials at one rate vertex.
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
            % Mixed-radix weights flatten Bernstein labels in combRows order.
            base = (vals{sum(nxt .* mult) + 1} - vals{sum(lbl .* mult) + 1}) ...
                .* (deg * rate(dim) / h(dim));

            % Each partial has degree m-1 in this dimension; elevate the
            % two affected Bernstein coefficients into the common degree m
            % tensor basis before accumulating the rate-weighted sum.
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
