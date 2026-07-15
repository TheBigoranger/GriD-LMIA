function order = chkPutinarOrder(expr, order)
    %CHKPUTINARORDER Validate or choose an absolute Putinar Gram order.
    %   The minimum ceil(expr.Degree/2) makes the even matching degree 2*order
    %   large enough to represent the original residual exactly.

    minOrder = ceil(expr.Degree / 2);
    if nargin < 2
        order = minOrder;
    end
    order = double(helper.chk(order, ...
        "pdlmi:InvalidPutinarOrder", ...
        "PutinarOrder must be a finite nonnegative integer scalar.", ...
        "numeric", "real", "finite", "integer", "nonnegative", "scalar"));
    if order < minOrder
        error("pdlmi:PutinarOrderTooLow", ...
            "PutinarOrder %d is below the minimum admissible order %d.", ...
            order, minOrder);
    end
end
