function vals = zipVals(obj, lhsVals, rhsVals, fcn, grid)
    %ZIPVALS Combine matching local coefficient payloads cell-by-cell.

    if nargin < 5
        grid = obj.GridInfo.Vectors;
    end

    nCell = cellfun(@numel, grid) - 1;
    vals = internal.mkNest(nCell, @(subs) cellfun(fcn, ...
        internal.cellGet(lhsVals, subs), internal.cellGet(rhsVals, subs), ...
        UniformOutput=false));
end
