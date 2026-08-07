function out = usePutinar(obj, varargin)
    %USEPUTINAR Rebuild the residual with a cell-local Putinar certificate.
    %
    %   Syntax:
    %     out = obj.usePutinar()
    %     out = obj.usePutinar(order)
    %     out = obj.usePutinar(order, "ValidationMode", mode)
    %
    %   Arguments:
    %     order - Optional absolute scalar shorthand or ell-element Gram order.
    %             The default is the minimum admissible order.
    %     mode  - Optional "fast" or "strict" assembly validation mode.
    %
    %   Output:
    %     out - New pdlmi wrapper rebuilt from obj.Residual and obj.Relation
    %           with dense Putinar selected. obj itself is unchanged.
    %
    %   Example:
    %     P = pdvar(2, [0 1], "symmetric");
    %     relaxed = (P >= 0).usePutinar();
    %
    %   A new call replaces any prior certificate selection. Equality wrappers
    %   and orders below the dimension-dependent minimum are rejected.

    if obj.Relation == "=="
        error("pdlmi:UnsupportedEqualityCertificate", ...
            "Coefficient equality supports direct assembly only.");
    end
    [args, mode] = applyArgs(varargin);
    if numel(args) > 1
        error("pdlmi:InvalidApplyOptions", ...
            "Too many positional inputs were supplied.");
    end
    if isempty(args)
        order = chkOrder(obj.Residual, "put");
    else
        order = chkOrder(obj.Residual, "put", args{1});
    end
    out = pdlmi(obj.Residual, obj.Relation, UsePutinar=true, ...
        PutinarOrder=order, ValidationMode=mode);
end
