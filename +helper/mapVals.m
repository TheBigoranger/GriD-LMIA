function vals = mapVals(vals, fcn, grid)
    %MAPVALS Apply one coefficient mapping over a nested LocalValues tree.

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) cellfun(fcn, ...
        helper.cellGet(vals, subs), UniformOutput=false));
end
