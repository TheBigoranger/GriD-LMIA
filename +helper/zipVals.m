function vals = zipVals(lhsVals, rhsVals, fcn, grid)
    %ZIPVALS Combine two matching nested LocalValues trees coefficient-wise.

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) cellfun(fcn, ...
        helper.cellGet(lhsVals, subs), helper.cellGet(rhsVals, subs), ...
        UniformOutput=false));
end
