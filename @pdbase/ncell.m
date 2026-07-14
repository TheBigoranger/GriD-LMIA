function n = ncell(obj)
    %NCELL Number of physical tensor-grid cells.
    %
    %   Syntax:
    %     n = ncell(obj)
    %     n = obj.ncell()
    %
    %   Example:
    %     obj = pdbase({[0 1 2], [10 20]}, [1 1], 0);
    %     n = obj.ncell();

    n = prod(obj.GridInfo.NumNodes - 1);
end
