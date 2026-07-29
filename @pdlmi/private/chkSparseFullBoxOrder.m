function order = chkSparseFullBoxOrder(expr, order)
    %CHKSPARSEFULLBOXORDER Validate or choose an absolute sparse-box order.
    %
    %   SparseFullBoxOrder accepts scalar uniform shorthand or an ell-element
    %   vector and returns a 1-by-ell row. Its minimum is floor(expr.Degree/2)
    %   in one parameter and componentwise ceil(expr.Degree/2) otherwise; the
    %   multidimensional matching target has degree 2.*order.

    if numel(expr.GridInfo.Vectors) == 1
        minOrder = floor(expr.Degree / 2);
    else
        minOrder = ceil(expr.Degree / 2);
    end
    if nargin < 2
        order = minOrder;
    end
    order = helper.normalizeDegree(order, expr.npar(), ...
        "pdlmi:InvalidSparseFullBoxOrder", "SparseFullBoxOrder");
    if any(order < minOrder)
        error("pdlmi:SparseFullBoxOrderTooLow", ...
            "SparseFullBoxOrder %s is below the minimum admissible order %s.", ...
            mat2str(order), mat2str(minOrder));
    end
end
