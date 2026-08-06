function order = chkSparsePutinarOrder(expr, order)
    %CHKSPARSEPUTINARORDER Validate or choose a SparsePutinar Gram order.
    %
    %   SparsePutinarOrder accepts scalar uniform shorthand or an ell-element
    %   vector and returns a 1-by-ell row. Its minimum is floor(Degree/2) in
    %   one parameter and componentwise ceil(Degree/2) otherwise.

    if isscalar(expr.GridInfo.Vectors)
        minOrder = floor(expr.Degree / 2);
    else
        minOrder = ceil(expr.Degree / 2);
    end
    if nargin < 2
        order = minOrder;
    end
    order = helper.normalizeDegree(order, expr.npar(), ...
        "pdlmi:InvalidSparsePutinarOrder", "SparsePutinarOrder");
    if any(order < minOrder)
        error("pdlmi:SparsePutinarOrderTooLow", ...
            "SparsePutinarOrder %s is below the minimum admissible order %s.", ...
            mat2str(order), mat2str(minOrder));
    end
end
