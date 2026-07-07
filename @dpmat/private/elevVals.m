function vals = elevVals(obj, vals, fromDeg, toDeg, grid)
    %ELEVVALS Degree-elevate every physical cell in a LocalValues tree.

    if fromDeg == toDeg
        return
    end
    if nargin < 5
        grid = obj.GridInfo.Vectors;
    end

    nCell = cellfun(@numel, grid) - 1;
    vals = internal.mkNest(nCell, @(subs) obj.bernElev(internal.cellGet(vals, subs), fromDeg, toDeg));
end
