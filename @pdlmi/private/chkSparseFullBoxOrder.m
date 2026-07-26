function order = chkSparseFullBoxOrder(expr, order)
    %CHKSPARSEFULLBOXORDER Validate or choose an absolute sparse-box order.
    %
    %   SparseFullBoxOrder follows FullBoxOrder's dimension-dependent contract:
    %   floor(expr.Degree/2) in one parameter and ceil(expr.Degree/2)
    %   otherwise.

    if numel(expr.GridInfo.Vectors) == 1
        minOrder = floor(expr.Degree / 2);
    else
        minOrder = ceil(expr.Degree / 2);
    end
    if nargin < 2
        order = minOrder;
    end
    order = double(helper.chk(order, ...
        "pdlmi:InvalidSparseFullBoxOrder", ...
        "SparseFullBoxOrder must be a finite nonnegative integer scalar.", ...
        "numeric", "real", "finite", "integer", "nonnegative", "scalar"));
    if order < minOrder
        error("pdlmi:SparseFullBoxOrderTooLow", ...
            "SparseFullBoxOrder %d is below the minimum admissible order %d.", ...
            order, minOrder);
    end
end
