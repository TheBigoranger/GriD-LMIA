function out = blkdiag(varargin)
    %BLKDIAG Block diagonal concatenation for coefficient-backed dpmat data.
    %
    %   Syntax:
    %     B = blkdiag(A, C)
    %     B = blkdiag(A, M)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     B = blkdiag(A, A);

    anchor = [];
    for k = 1:numel(varargin)
        if isa(varargin{k}, "dpmat")
            anchor = varargin{k};
            break
        end
    end
    if isempty(anchor)
        error("dpmat:InvalidBlkdiag", ...
            "At least one blkdiag input must be a dpmat.");
    end

    grid = anchor.mergeGrid("dpmat:MixedGrid", varargin{:});
    data = repmat(struct("MatrixSize", [], "Degree", [], ...
        "LocalValues", [], "IsContinuous", []), 1, numel(varargin));
    for k = 1:numel(varargin)
        data(k) = asData(grid, varargin{k}, [], "dpmat:InvalidBlkdiag");
    end

    deg = max(arrayfun(@(d) d.Degree, data));
    for k = 1:numel(data)
        data(k).LocalValues = elevVals(anchor, data(k).LocalValues, ...
            data(k).Degree, deg, grid);
    end

    nCell = cellfun(@numel, grid) - 1;
    vals = internal.mkNest(nCell, @(subs) blkCell(data, subs));
    out = dpmat(grid, vals, Degree=deg);
end

function coeffs = blkCell(data, subs)
    nCoeff = numel(internal.cellGet(data(1).LocalValues, subs));
    coeffs = cell(1, nCoeff);
    for c = 1:nCoeff
        parts = cell(1, numel(data));
        for k = 1:numel(data)
            one = internal.cellGet(data(k).LocalValues, subs);
            parts{k} = one{c};
        end

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
        coeffs{c} = val;
    end
end
