function out = zeroObj(grid, sz)
    %ZEROOBJ Build a degree-zero coefficient-backed zero dpmat.

    info = helper.mkGrid(grid, "dpmat");
    vals = helper.mkNest(info.NumNodes - 1, @(~) {zeros(sz)});
    out = mkObj(grid, vals, 0);
end
