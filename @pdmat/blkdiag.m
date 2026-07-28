function out = blkdiag(varargin)
    %BLKDIAG Block diagonal concatenation for coefficient-backed pdmat data.
    %
    %   Syntax:
    %     B = blkdiag(A, C)
    %     B = blkdiag(A, M)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     B = blkdiag(A, A);

    anchor = [];
    for k = 1:numel(varargin)
        if isa(varargin{k}, "pdmat")
            anchor = varargin{k};
            break
        end
    end
    if isempty(anchor)
        error("pdmat:InvalidBlkdiag", ...
            "At least one blkdiag input must be a pdmat.");
    end

    rb = anchor.pickRateBounds("pdmat:InvalidBlkdiag", varargin{:});
    grid = anchor.mergeGrid("pdmat:MixedGrid", varargin{:});
    data = repmat(struct("MatrixSize", [], "Degree", [], ...
        "LocalValues", [], "IsContinuous", [], ...
        "HasRateDependence", [], "HasRateRows", []), 1, numel(varargin));
    for k = 1:numel(varargin)
        data(k) = asData(grid, varargin{k}, [], rb, ...
            "pdmat:InvalidBlkdiag");
    end

    deg = max(arrayfun(@(d) d.Degree, data));
    data = pdbase.alignLocalDegrees(data, deg, grid);

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) blkCell(anchor, data, subs));
    if ~any(arrayfun(@(d) d.HasRateDependence, data))
        rb = [];
    end
    out = mkObj(grid, vals, deg, rb);
end

function coeffs = blkCell(anchor, data, subs)
    %BLKCELL Assemble one physical cell's block-diagonal coefficients.
    leaves = cell(1, numel(data));
    for k = 1:numel(data)
        leaves{k} = helper.cellGet(data(k).LocalValues, subs);
    end
    coeffs = anchor.joinRateRows(leaves, @oneBlkdiag, ...
        "pdmat:InvalidCoefficientRows");
end

function val = oneBlkdiag(parts)
    %ONEBLKDIAG Assemble one aligned coefficient block diagonal.
        rows = cellfun(@(a) size(a, 1), parts);
        cols = cellfun(@(a) size(a, 2), parts);
        val = zeros(sum(rows), sum(cols));
        row = 1;
        col = 1;
        for k = 1:numel(parts)
            rr = row:(row + rows(k) - 1);
            cc = col:(col + cols(k) - 1);
            val(rr, cc) = parts{k};
            row = row + rows(k);
            col = col + cols(k);
        end
end
