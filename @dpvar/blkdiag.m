function out = blkdiag(varargin)
    %BLKDIAG Block diagonal concatenation for dpvar-compatible data.
    %
    %   Syntax:
    %     B = blkdiag(P, Q)
    %     B = blkdiag(P, A)
    %
    %   Example:
    %     P = dpvar(1, {[0 1]});
    %     B = blkdiag(P, eye(2));

    anchor = pickAnchor(varargin);
    grid = anchor.mergeGrid("dpvar:MixedGrid", varargin{:});
    data = repmat(struct("MatrixSize", [], "Degree", [], ...
        "LocalValues", [], "ContainsDecision", [], "HasRateDependence", [], ...
        "IsContinuous", [], "HasRateRows", []), ...
        1, numel(varargin));
    for k = 1:numel(varargin)
        data(k) = asData(grid, varargin{k}, [], anchor.RateBounds, ...
            "dpvar:InvalidBlkdiag");
    end

    deg = max(arrayfun(@(d) d.Degree, data));
    for k = 1:numel(data)
        data(k).LocalValues = elevVals(anchor, data(k).LocalValues, ...
            data(k).Degree, deg, grid);
    end

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) blkCell(data, subs));
    sz = [sum(arrayfun(@(d) d.MatrixSize(1), data)), ...
        sum(arrayfun(@(d) d.MatrixSize(2), data))];
    hasDec = any(arrayfun(@(d) d.ContainsDecision, data));
    hasRate = any(arrayfun(@(d) d.HasRateDependence, data));
    rb = anchor.RateBounds;
    if ~hasRate
        rb = [];
    end

    out = dpvar(mkInit(grid, sz, deg, vals, hasDec, hasRate, rb, "expression"));
end

function anchor = pickAnchor(args)
    anchor = [];
    for k = 1:numel(args)
        if isa(args{k}, "dpvar")
            anchor = args{k};
            break
        end
    end
    if isempty(anchor)
        error("dpvar:InvalidBlkdiag", ...
            "At least one blkdiag input must be a dpvar.");
    end
end

function coeffs = blkCell(data, subs)
    nCoeff = numel(helper.cellGet(data(1).LocalValues, subs));
    coeffs = cell(1, nCoeff);
    for c = 1:nCoeff
        parts = cell(1, numel(data));
        for k = 1:numel(data)
            one = helper.cellGet(data(k).LocalValues, subs);
            parts{k} = one{c};
        end
        coeffs{c} = blkdiag(parts{:});
    end
end
