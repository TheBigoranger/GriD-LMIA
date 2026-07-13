function order = validateFullBoxOrder(expr, order)
    %VALIDATEFULLBOXORDER Enforce the absolute order contract on every path.
    %   Malformed values and well-formed but insufficient orders intentionally
    %   use different identifiers so callers can distinguish input errors from
    %   certificate-degree errors.

    order = double(helper.chk(order, ...
        "dplmi:InvalidFullBoxOrder", ...
        "FullBoxOrder must be a finite nonnegative integer scalar.", ...
        "numeric", "real", "finite", "integer", "nonnegative", "scalar"));
    if numel(expr.GridInfo.Vectors) == 1
        minOrder = floor(expr.Degree / 2);
    else
        minOrder = ceil(expr.Degree / 2);
    end
    if order < minOrder
        error("dplmi:FullBoxOrderTooLow", ...
            "FullBoxOrder %d is below the minimum admissible order %d.", ...
            order, minOrder);
    end
end
