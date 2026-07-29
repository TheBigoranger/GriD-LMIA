function order = chkPutinarOrder(expr, order)
    %CHKPUTINARORDER Validate or choose an absolute Putinar Gram order.
    %
    %   Syntax:
    %     order = chkPutinarOrder(expr)
    %     order = chkPutinarOrder(expr, order)
    %
    %   Arguments:
    %     expr  - pdvar residual that supplies the Bernstein degree vector.
    %     order - Optional scalar shorthand or ell-element absolute order.
    %
    %   Output:
    %     order - Admissible absolute Gram order as a 1-by-ell row vector.
    %
    %   In one parameter, the minimum floor(expr.Degree/2) selects the exact
    %   parity-specific Markov-Lukacs certificate. Otherwise,
    %   componentwise ceil(expr.Degree/2) makes the matching degree 2.*order
    %   large enough to represent the original residual exactly.

    if isscalar(expr.GridInfo.Vectors)
        minOrder = floor(expr.Degree / 2);
    else
        minOrder = ceil(expr.Degree / 2);
    end
    if nargin < 2
        order = minOrder;
    end
    order = helper.normalizeDegree(order, expr.npar(), ...
        "pdlmi:InvalidPutinarOrder", "PutinarOrder");
    if any(order < minOrder)
        error("pdlmi:PutinarOrderTooLow", ...
            "PutinarOrder %s is below the minimum admissible order %s.", ...
            mat2str(order), mat2str(minOrder));
    end
end
