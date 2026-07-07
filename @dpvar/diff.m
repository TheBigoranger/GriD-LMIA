function out = diff(obj, varargin)
    %DIFF Cell-local Bernstein partial derivatives of a dpvar expression.
    %
    %   Syntax:
    %     D = diff(P)
    %
    %   Example:
    %     P = dpvar(1, {[0 1 2]}, RateBounds=[-1 1]);
    %     D = diff(P);
    %
    %   D stores one derivative coefficient row per parameter direction in
    %   each physical hypercube. These rows are discontinuous cell-local data.

    if nargin ~= 1 || ~isempty(varargin)
        error("dpvar:InvalidDiff", ...
            "dpvar diff currently supports only D = diff(P).");
    end
    if isDeriv(obj)
        error("dpvar:InvalidDiff", ...
            "Taking diff of derivative-row dpvar expressions is unsupported.");
    end
    if ~obj.HasRateDependence
        warning("dpvar:NoRateDependence", ...
            "diff(P) is using grid-local derivatives without rate metadata on P.");
    end

    srcDeg = obj.Degree;
    deg = max(srcDeg - 1, 0);
    grid = obj.GridInfo.Vectors;
    nCell = cellfun(@numel, grid) - 1;

    vals = internal.mkNest(nCell, @(subs) diffRows(obj, subs, srcDeg, grid));
    out = dpvar(mkInit(grid, obj.MatrixSize, deg, vals, ...
        obj.ContainsDecision, obj.HasRateDependence, obj.RateBounds, ...
        "derivative", IsContinuous=false, DerivativeSourceDegree=srcDeg));
end

function rows = diffRows(obj, subs, srcDeg, grid)
    nPar = obj.npar();
    coeffs = internal.cellGet(obj.LocalValues, subs);
    rows = cell(1, nPar);

    if srcDeg == 0
        z = zeros(size(coeffs{1}));
        for r = 1:nPar
            rows{r} = {z};
        end
        return
    end

    for r = 1:nPar
        h = grid{r}(subs(r) + 1) - grid{r}(subs(r));
        lbls = rowLbls(srcDeg, nPar, r);
        row = cell(1, size(lbls, 1));
        for k = 1:size(lbls, 1)
            lo = lbls(k, :);
            hi = lo;
            hi(r) = hi(r) + 1;
            % Bernstein derivative coefficients stay local to this
            % hypercube; adjacent cells are intentionally not merged.
            row{k} = (srcDeg / h) .* ...
                (coeffs{lblIdx(hi, srcDeg)} - coeffs{lblIdx(lo, srcDeg)});
        end
        rows{r} = row;
    end
end

function lbls = rowLbls(srcDeg, nPar, dim)
    vecs = repmat({0:srcDeg}, 1, nPar);
    vecs{dim} = 0:(srcDeg - 1);
    lbls = internal.combRows(vecs);
end

function idx = lblIdx(lbl, deg)
    mult = (deg + 1) .^ (numel(lbl) - 1:-1:0);
    idx = sum(lbl .* mult) + 1;
end
