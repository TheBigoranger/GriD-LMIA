function vals = mapVals(vals, fcn, grid)
    %MAPVALS Apply one coefficient mapping over a nested LocalValues tree.

    nCell = cellfun(@numel, grid) - 1;
    vals = internal.mkNest(nCell, @(subs) cellfun(fcn, ...
        internal.cellGet(vals, subs), UniformOutput=false));
end
