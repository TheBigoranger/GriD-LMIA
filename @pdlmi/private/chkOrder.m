function order = chkOrder(expr, family, order)
    %CHKORDER Validate or choose one certificate-family Gram order.
    %
    %   Syntax:
    %     order = chkOrder(expr, family)
    %     order = chkOrder(expr, family, order)
    %
    %   Arguments:
    %     expr   - Residual object supplying Degree and npar().
    %     family - "put", "box", "spPut", or "spBox".
    %     order  - Optional scalar shorthand or ell-element absolute order.
    %
    %   Output:
    %     order - 1-by-ell admissible Gram order for the selected family.
    %
    %   Example:
    %     order = chkOrder(expr, "spPut", [2 2]);
    %
    %   Omitted orders use the dimension-dependent minimum: floor(Degree/2)
    %   in one parameter and ceil(Degree/2) otherwise. Family-specific error
    %   identifiers are preserved so public constructors and apply methods can
    %   report the option name the user supplied.

    names = struct( ...
        "put", ["PutinarOrder", "InvalidPutinarOrder", "PutinarOrderTooLow"], ...
        "box", ["FullBoxOrder", "InvalidFullBoxOrder", "FullBoxOrderTooLow"], ...
        "spPut", ["SparsePutinarOrder", "InvalidSparsePutinarOrder", "SparsePutinarOrderTooLow"], ...
        "spBox", ["SparseFullBoxOrder", "InvalidSparseFullBoxOrder", "SparseFullBoxOrderTooLow"]);
    if ~isfield(names, family)
        error("pdlmi:InvalidOrderFamily", ...
            "Unknown certificate order family %s.", family);
    end
    ids = names.(family);
    if expr.npar() == 1
        minimum = floor(expr.Degree / 2);
    else
        minimum = ceil(expr.Degree / 2);
    end
    if nargin < 3
        order = minimum;
    end
    order = helper.normDeg(order, expr.npar(), ...
        "pdlmi:" + ids(2), ids(1));
    if any(order < minimum)
        error("pdlmi:" + ids(3), ...
            "%s %s is below the minimum admissible order %s.", ...
            ids(1), mat2str(order), mat2str(minimum));
    end
end
