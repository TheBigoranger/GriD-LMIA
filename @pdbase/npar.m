function n = npar(obj)
    %NPAR Number of parameter dimensions in the tensor grid.
    %
    %   Syntax:
    %     n = npar(obj)
    %     n = obj.npar()
    %
    %   Example:
    %     obj = pdbase({[0 1], [10 20]}, [1 1], 0);
    %     n = obj.npar();

    n = numel(obj.GridInfo.Vectors);
end
