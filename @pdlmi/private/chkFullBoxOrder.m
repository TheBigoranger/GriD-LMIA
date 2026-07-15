function order = chkFullBoxOrder(expr, order)
    %CHKFULLBOXORDER Enforce the absolute order contract on every path.
    %   Omitting ORDER selects the parity/dimension-dependent minimum.
    %   Malformed values and well-formed but insufficient orders intentionally
    %   use different identifiers so callers can distinguish input errors from
    %   certificate-degree errors.

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
