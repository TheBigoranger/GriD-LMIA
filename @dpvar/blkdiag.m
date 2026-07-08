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

    anchor = pickAnchor("dpvar:InvalidBlkdiag", varargin);
    grid = anchor.mergeGrid("dpvar:MixedGrid", varargin{:});
    rb = pickRb("dpvar:InvalidBlkdiag", varargin{:});
    data = repmat(struct("MatrixSize", [], "Degree", [], ...
        "LocalValues", [], "ContainsDecision", [], "HasRateDependence", [], ...
        "IsContinuous", [], "HasRateRows", []), ...
        1, numel(varargin));
    for k = 1:numel(varargin)
        data(k) = asData(grid, varargin{k}, [], rb, ...
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
    if ~hasRate
        rb = [];
    end

    out = dpvar(mkInit(grid, sz, deg, vals, hasDec, hasRate, rb, ...
        "expression", all(arrayfun(@(d) d.IsContinuous, data))));
end

function coeffs = blkCell(data, subs)
    leaves = cell(1, numel(data));
    for k = 1:numel(data)
        leaves{k} = helper.cellGet(data(k).LocalValues, subs);
    end
    % Block diagonal assembly follows the same rate-row broadcast contract
    % as cat: derivative rows stay row-wise, ordinary rows expand to them.
    coeffs = joinRows(leaves, @(parts) blkdiag(parts{:}), ...
        "dpvar:InvalidCoefficientRows");
end
