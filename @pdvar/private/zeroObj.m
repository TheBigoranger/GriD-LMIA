function out = zeroObj(grid, sz)
    %ZEROOBJ Build a degree-zero zero pdvar expression.

    info = helper.mkGrid(grid, "pdvar");
    vals = helper.mkNest(info.NumNodes - 1, @(~) {zeros(sz)});
    out = pdvar(mkInit(grid, sz, 0, vals, false, false, [], ...
        "expression", true));
end
