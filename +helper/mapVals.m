function vals = mapVals(vals, fcn, grid)
    %MAPVALS Apply one coefficient mapping over a nested LocalValues tree.
    %
    %   Syntax:
    %     vals = helper.mapVals(vals, fcn, grid)
    %
    %   Arguments:
    %     vals - Nested LocalValues tree.
    %     fcn  - Mapping applied to every payload in each leaf.
    %     grid - Physical grid defining the nested tree shape.
    %
    %   Output:
    %     vals - Mapped tree with the same physical-cell layout.

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) cellfun(fcn, ...
        helper.cellGet(vals, subs), UniformOutput=false));
end
