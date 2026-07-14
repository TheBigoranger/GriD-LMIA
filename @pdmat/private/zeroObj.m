function out = zeroObj(grid, sz)
    %ZEROOBJ Build a degree-zero coefficient-backed zero pdmat.

    info = helper.mkGrid(grid, "pdmat");
    vals = helper.mkNest(info.NumNodes - 1, @(~) {zeros(sz)});
    out = mkObj(grid, vals, 0);
end
