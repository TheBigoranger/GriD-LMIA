function rows = combRows(vecs)
    %COMBROWS Cartesian product rows in shared combination order.
    %
    %   Syntax:
    %     rows = helper.combRows(vecs)
    %
    %   Arguments:
    %     vecs - Cell array containing one vector per tensor axis.
    %
    %   Output:
    %     rows - Cartesian combinations with earlier axes varying more slowly.
    %
    %   Example:
    %     rows = helper.combRows({0:1, 10:11});

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
        % MATLAB may preserve a row orientation when a singleton axis is
        % repeated; flatten explicitly so every tensor axis fills one column.
        col = col(:);
        rows(:, dim) = repmat(col, rep, 1);
    end
end
