function out = lbls(obj)
    %LBLS Local Bernstein labels in flat coefficient order.
    %
    %   Syntax:
    %     out = lbls(obj)
    %     out = obj.lbls()
    %
    %   Arguments:
    %     obj - Gridded object supplying degree and parameter count.
    %
    %   Output:
    %     out - Local tensor labels in flat coefficient-column order.
    %
    %   Example:
    %     obj = pdbase({[0 1], [10 20]}, [1 1], 1);
    %     out = obj.lbls();

    vecs = arrayfun(@(deg) 0:deg, obj.Degree, ...
        "UniformOutput", false);
    out = helper.combRows(vecs);
end
