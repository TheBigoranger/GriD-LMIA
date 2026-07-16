function order = chkFullBoxOrder(expr, order)
    %CHKFULLBOXORDER Validate or choose an absolute full-box Gram order.
    %
    %   Syntax:
    %     order = chkFullBoxOrder(expr)
    %     order = chkFullBoxOrder(expr, order)
    %
    %   Arguments:
    %     expr  - pdvar residual that supplies the parameter dimension and degree.
    %     order - Optional finite nonnegative integer scalar order.
    %
    %   Output:
    %     order - Admissible absolute Gram order for the full box preordering.
    %
    %   In one parameter, an omitted order is floor(expr.Degree/2); otherwise
    %   it is ceil(expr.Degree/2). Malformed and insufficient orders retain
    %   distinct error identifiers for input versus certificate-degree errors.

    if nargin < 2
        if numel(expr.GridInfo.Vectors) == 1
            order = floor(expr.Degree / 2);
        else
            order = ceil(expr.Degree / 2);
        end
    end
    order = double(helper.chk(order, ...
        "pdlmi:InvalidFullBoxOrder", ...
        "FullBoxOrder must be a finite nonnegative integer scalar.", ...
        "numeric", "real", "finite", "integer", "nonnegative", "scalar"));
    if numel(expr.GridInfo.Vectors) == 1
        minOrder = floor(expr.Degree / 2);
    else
        minOrder = ceil(expr.Degree / 2);
    end
    if order < minOrder
        error("pdlmi:FullBoxOrderTooLow", ...
            "FullBoxOrder %d is below the minimum admissible order %d.", ...
            order, minOrder);
    end
end
