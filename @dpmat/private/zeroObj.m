function out = zeroObj(grid, sz)
    %ZEROOBJ Build a degree-zero coefficient-backed zero dpmat.

    info = helper.mkGrid(grid, "dpmat");
    vals = helper.mkNest(info.NumNodes - 1, @(~) {zeros(sz)});
    out = dpmat(grid, vals, Degree=0);
end
