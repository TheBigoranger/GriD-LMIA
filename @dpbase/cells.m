function subs = cells(obj)
    %CELLS Enumerate physical-cell subscripts in combination order.
    %
    %   Syntax:
    %     subs = cells(obj)
    %     subs = obj.cells()
    %
    %   Example:
    %     obj = dpbase({[0 1 2], [10 20]}, [1 1], 0);
    %     subs = obj.cells();

    n = obj.GridInfo.NumNodes - 1;
    vecs = arrayfun(@(k) 1:k, n, "UniformOutput", false);
    subs = combRows(vecs);
end
