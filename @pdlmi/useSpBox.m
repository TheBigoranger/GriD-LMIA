function out = useSpBox(obj, varargin)
    %USESPBOX Rebuild the residual with a tensor-window full-box certificate.
    %
    %   Syntax:
    %     out = obj.useSpBox()
    %     out = obj.useSpBox(bandWidth)
    %     out = obj.useSpBox(bandWidth, order)
    %     out = obj.useSpBox(bandWidth, order, "ValidationMode", mode)
    %
    %   Arguments:
    %     bandWidth - Optional positive tensor-window side length. The default
    %                 is two.
    %     order     - Optional absolute scalar shorthand or ell-element Gram
    %                 order. The default is the minimum admissible order.
    %     mode      - Optional "fast" or "strict" assembly validation mode.
    %
    %   Output:
    %     out - New pdlmi wrapper rebuilt from obj.Residual and obj.Relation
    %           with sparse full-box requested. Endpoint widths may normalize
    %           to actual Direct or full-box state.
    %
    %   Example:
    %     P = pdvar(2, [0 1], "symmetric");
    %     relaxed = (P >= 0).useSpBox(2, 1);
    %
    %   A new call replaces any prior certificate selection. Equality wrappers,
    %   invalid window widths, and orders below the dimension-dependent minimum
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
        bandWidth = 2;
    else
        bandWidth = args{1};
    end
    bandWidth = chkBand(bandWidth);
    if numel(args) < 2
        order = chkOrder(obj.Residual, "spBox");
    else
        order = chkOrder(obj.Residual, "spBox", args{2});
    end
    out = pdlmi(obj.Residual, obj.Relation, ...
        UseSparseFullBoxPreorder=true, BandWidth=bandWidth, ...
        SparseFullBoxOrder=order, ValidationMode=mode);
end
