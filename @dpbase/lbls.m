function out = lbls(obj)
    %LBLS Local Bernstein labels in flat coefficient order.
    %
    %   Syntax:
    %     out = lbls(obj)
    %     out = obj.lbls()
    %
    %   Example:
    %     obj = dpbase({[0 1], [10 20]}, [1 1], 1);
    %     out = obj.lbls();

    nPar = obj.npar();
    vecs = repmat({0:obj.Degree}, 1, nPar);
    out = combRows(vecs);
end
