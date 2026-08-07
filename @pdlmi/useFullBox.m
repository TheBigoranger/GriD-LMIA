function out = useFullBox(obj, varargin)
    %USEFULLBOX Rebuild the residual with a full-box certificate.
    %
    %   Syntax:
    %     out = obj.useFullBox()
    %     out = obj.useFullBox(order)
    %     out = obj.useFullBox(order, "ValidationMode", mode)
    %
    %   Arguments:
    %     order - Optional absolute scalar shorthand or ell-element Gram order.
    %             The default is the minimum admissible order.
    %     mode  - Optional "fast" or "strict" assembly validation mode.
    %
    %   Output:
    %     out - New pdlmi wrapper rebuilt from obj.Residual and obj.Relation
    %           with full-box preordering selected. obj itself is unchanged.
    %
    %   Example:
    %     P = pdvar(2, [0 1], "symmetric");
    %     relaxed = (P >= 0).useFullBox();
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
        order = chkOrder(obj.Residual, "box");
    else
        order = chkOrder(obj.Residual, "box", args{1});
    end
    out = pdlmi(obj.Residual, obj.Relation, ...
        UseFullBoxPreorder=true, FullBoxOrder=order, ...
        ValidationMode=mode);
end
