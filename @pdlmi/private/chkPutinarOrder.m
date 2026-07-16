function order = chkPutinarOrder(expr, order)
    %CHKPUTINARORDER Validate or choose an absolute Putinar Gram order.
    %
    %   Syntax:
    %     order = chkPutinarOrder(expr)
    %     order = chkPutinarOrder(expr, order)
    %
    %   Arguments:
    %     expr  - pdvar residual that supplies the scalar Bernstein degree.
    %     order - Optional finite nonnegative integer scalar order.
    %
    %   Output:
    %     order - Admissible absolute Gram order for the Putinar certificate.
    %
    %   In one parameter, the minimum floor(expr.Degree/2) selects the exact
    %   parity-specific Markov-Lukacs certificate. Otherwise,
    %   ceil(expr.Degree/2) makes the even matching degree 2*order large enough
    %   to represent the original residual exactly.

    if isscalar(expr.GridInfo.Vectors)
        minOrder = floor(expr.Degree / 2);
    else
        minOrder = ceil(expr.Degree / 2);
    end
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
