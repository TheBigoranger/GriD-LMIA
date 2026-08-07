function out = useSpPut(obj, varargin)
    %USESPPUT Rebuild the residual with a tensor-window Putinar certificate.
    %
    %   Syntax:
    %     out = obj.useSpPut()
    %     out = obj.useSpPut(cliqueSize)
    %     out = obj.useSpPut(cliqueSize, order)
    %     out = obj.useSpPut(cliqueSize, order, "ValidationMode", mode)
    %
    %   Arguments:
    %     cliqueSize - Optional positive tensor-window side length. The
    %                  default is two.
    %     order      - Optional absolute scalar shorthand or ell-element Gram
    %                  order. The default is the minimum admissible order.
    %     mode       - Optional "fast" or "strict" assembly validation mode.
    %
    %   Output:
    %     out - New pdlmi wrapper rebuilt from obj.Residual and obj.Relation
    %           with SparsePutinar requested. Endpoint windows may normalize
    %           to actual Direct or dense Putinar state.
    %
    %   Example:
    %     P = pdvar(2, [0 1], "symmetric");
    %     relaxed = (P >= 0).useSpPut(2, 1);
    %
    %   A new call replaces any prior certificate selection. Equality wrappers,
    %   invalid window sizes, and orders below the dimension-dependent minimum
    %   are rejected.

    if obj.Relation == "=="
        error("pdlmi:UnsupportedEqualityCertificate", ...
            "Coefficient equality supports direct assembly only.");
    end
    [args, mode] = applyArgs(varargin);
    if numel(args) > 2
        error("pdlmi:InvalidApplyOptions", ...
            "Too many positional inputs were supplied.");
    end
    if isempty(args)
        cliqueSize = 2;
    else
        cliqueSize = args{1};
    end
    cliqueSize = chkClique(cliqueSize);
    if numel(args) < 2
        order = chkOrder(obj.Residual, "spPut");
    else
        order = chkOrder(obj.Residual, "spPut", args{2});
    end
    out = pdlmi(obj.Residual, obj.Relation, ...
        UseSparsePutinar=true, CliqueSize=cliqueSize, ...
        SparsePutinarOrder=order, ValidationMode=mode);
end
