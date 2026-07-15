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

    nPar = obj.npar();
    vecs = repmat({0:obj.Degree}, 1, nPar);
    out = helper.combRows(vecs);
end
