function vals = zipRateRows(obj, lhsVals, rhsVals, fcn, grid, errId)
    %ZIPRATEROWS Combine nested coefficient trees with one-row broadcasting.

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) obj.joinRateRows( ...
        {helper.cellGet(lhsVals, subs), helper.cellGet(rhsVals, subs)}, ...
        @(parts) fcn(parts{1}, parts{2}), errId));
end
