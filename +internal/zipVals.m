function vals = zipVals(lhsVals, rhsVals, fcn, grid)
    %ZIPVALS Combine two matching nested LocalValues trees coefficient-wise.

    nCell = cellfun(@numel, grid) - 1;
    vals = internal.mkNest(nCell, @(subs) cellfun(fcn, ...
        internal.cellGet(lhsVals, subs), internal.cellGet(rhsVals, subs), ...
        UniformOutput=false));
end
