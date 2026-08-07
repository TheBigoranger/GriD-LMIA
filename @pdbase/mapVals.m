function vals = mapVals(vals, fcn, grid)
    %MAPVALS Apply a coefficient mapping over shared LocalValues storage.
    %
    %   Syntax:
    %     vals = obj.mapVals(vals, fcn, grid)
    %
    %   Arguments:
    %     vals - Nested LocalValues tree.
    %     fcn  - Mapping applied to every payload in each leaf.
    %     grid - Physical grid defining the nested tree shape.
    %
    %   Output:
    %     vals - Mapped tree with the same physical-cell layout.
    %
    %   This protected utility keeps physical-cell traversal in pdbase while
    %   allowing subclasses to define the mapping applied within each leaf.
    %
    %   Example:
    %     vals = obj.mapVals(obj.LocalValues, @(a) -a, obj.GridInfo.Vectors);

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) cellfun(fcn, ...
        helper.cellGet(vals, subs), UniformOutput=false));
end
