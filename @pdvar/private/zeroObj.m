function out = zeroObj(grid, sz)
    %ZEROOBJ Build a degree-zero zero pdvar expression.

    info = helper.mkGrid(grid, "pdvar");
    vals = helper.mkNest(info.NumNodes - 1, @(~) {zeros(sz)});
    out = pdvar(mkInit(grid, sz, zeros(1, numel(grid)), ...
        vals, false, false, [], ...
        "expression", true));
end
