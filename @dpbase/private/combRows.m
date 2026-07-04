function rows = combRows(vecs)
    %COMBROWS Cartesian product rows in MATLAB-style combination order.

    nDim = numel(vecs);
    n = cellfun(@numel, vecs);
    % nRow is the flat product size used by both physical cells and labels.
    nRow = prod(n);
    rows = zeros(nRow, nDim);
    for dim = 1:nDim
        % Earlier dimensions vary more slowly; this matches MATLAB combinations
        % ordering and keeps physical-cell rows aligned with Bernstein labels.
        blk = prod(n(dim + 1:end));
        rep = prod(n(1:dim - 1));
        col = repelem(reshape(vecs{dim}, [], 1), blk);
        rows(:, dim) = repmat(col, rep, 1);
    end
end
