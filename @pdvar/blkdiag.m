function out = blkdiag(varargin)
    %BLKDIAG Block diagonal concatenation for pdvar-compatible data.
    %
    %   Syntax:
    %     B = blkdiag(P, Q)
    %     B = blkdiag(P, A)
    %
    %   Example:
    %     P = pdvar(1, {[0 1]});
    %     B = blkdiag(P, eye(2));

    anchor = pickAnchor("pdvar:InvalidBlkdiag", varargin);
    grid = anchor.mergeGrid("pdvar:MixedGrid", varargin{:});
    rb = anchor.pickRateBounds("pdvar:InvalidBlkdiag", varargin{:});
    data = repmat(struct("MatrixSize", [], "Degree", [], ...
        "LocalValues", [], "ContainsDecision", [], "HasRateDependence", [], ...
        "IsContinuous", [], "HasRateRows", []), ...
        1, numel(varargin));
    for k = 1:numel(varargin)
        data(k) = asData(grid, varargin{k}, [], rb, ...
            "pdvar:InvalidBlkdiag");
    end

    deg = max(arrayfun(@(d) d.Degree, data));
    data = pdbase.alignLocalDegrees(data, deg, grid);

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) blkCell(anchor, data, subs));
    sz = [sum(arrayfun(@(d) d.MatrixSize(1), data)), ...
        sum(arrayfun(@(d) d.MatrixSize(2), data))];
    hasDec = any(arrayfun(@(d) d.ContainsDecision, data));
    hasRate = any(arrayfun(@(d) d.HasRateDependence, data));
    if ~hasRate
        rb = [];
    end

    out = pdvar(mkInit(grid, sz, deg, vals, hasDec, hasRate, rb, ...
        "expression", all(arrayfun(@(d) d.IsContinuous, data))));
end

function coeffs = blkCell(anchor, data, subs)
    %BLKCELL Assemble aligned block diagonals with rate-row broadcasting.
    leaves = cell(1, numel(data));
    for k = 1:numel(data)
        leaves{k} = helper.cellGet(data(k).LocalValues, subs);
    end
    % Block diagonal assembly follows the same rate-row broadcast contract
    % as cat: derivative rows stay row-wise, ordinary rows expand to them.
    coeffs = anchor.joinRateRows(leaves, @(parts) blkdiag(parts{:}), ...
        "pdvar:InvalidCoefficientRows");
end
