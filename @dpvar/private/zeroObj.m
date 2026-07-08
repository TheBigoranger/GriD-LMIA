function out = zeroObj(grid, sz)
    %ZEROOBJ Build a degree-zero zero dpvar expression.

    info = helper.mkGrid(grid, "dpvar");
    vals = helper.mkNest(info.NumNodes - 1, @(~) {zeros(sz)});
    out = dpvar(mkInit(grid, sz, 0, vals, false, false, [], ...
        "expression", true));
end
