function tf = isRateRows(vals, grid, nCoeff)
    %ISRATEROWS True when LocalValues leaves are rate-vertex cell tables.

    nPar = numel(grid);
    leaf = helper.cellGet(vals, ones(1, nPar));
    tf = iscell(leaf) && size(leaf, 1) > 1 && size(leaf, 2) == nCoeff;
end
