function order = chkFullBoxOrder(expr, order)
    %CHKFULLBOXORDER Validate or choose an absolute full-box Gram order.
    %
    %   Syntax:
    %     order = chkFullBoxOrder(expr)
    %     order = chkFullBoxOrder(expr, order)
    %
    %   Arguments:
    %     expr  - pdvar residual that supplies the parameter dimension and degree.
    %     order - Optional scalar shorthand or ell-element absolute order.
    %
    %   Output:
    %     order - Admissible absolute Gram order as a 1-by-ell row vector.
    %
    %   In one parameter, an omitted order is floor(expr.Degree/2); otherwise
    %   it is componentwise ceil(expr.Degree/2), with target degree 2.*order.
    %   Malformed and insufficient orders retain
    %   distinct error identifiers for input versus certificate-degree errors.

    if nargin < 2
        if numel(expr.GridInfo.Vectors) == 1
            order = floor(expr.Degree / 2);
        else
            order = ceil(expr.Degree / 2);
        end
    end
    order = helper.normalizeDegree(order, expr.npar(), ...
        "pdlmi:InvalidFullBoxOrder", "FullBoxOrder");
    if numel(expr.GridInfo.Vectors) == 1
        minOrder = floor(expr.Degree / 2);
    else
        minOrder = ceil(expr.Degree / 2);
    end
    if any(order < minOrder)
        error("pdlmi:FullBoxOrderTooLow", ...
            "FullBoxOrder %s is below the minimum admissible order %s.", ...
            mat2str(order), mat2str(minOrder));
    end
end
