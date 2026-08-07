function out = usePolya(obj, varargin)
    %USEPOLYA Rebuild the residual with a selected Pólya degree increment.
    %
    %   Syntax:
    %     out = obj.usePolya()
    %     out = obj.usePolya(increment)
    %     out = obj.usePolya(increment, "ValidationMode", mode)
    %
    %   Arguments:
    %     increment - Optional nonnegative scalar shorthand or ell-element
    %                 degree increment. The default is one in every parameter.
    %     mode      - Optional "fast" or "strict" assembly validation mode.
    %
    %   Output:
    %     out - New pdlmi wrapper rebuilt from obj.Residual and obj.Relation
    %           with Pólya selected. obj itself is unchanged.
    %
    %   Example:
    %     P = pdvar(2, [0 1], "symmetric");
    %     relaxed = (P >= 0).usePolya(2);
    %
    %   A new call replaces any prior certificate selection rather than
    %   compounding it. Equality wrappers and invalid increments are rejected.

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
        increment = 1;
    else
        increment = args{1};
    end
    increment = helper.normDeg(increment, obj.Residual.npar(), ...
        "pdlmi:InvalidPolyaDegree", "PolyaDegree");
    out = pdlmi(obj.Residual, obj.Relation, UsePolya=true, ...
        PolyaDegree=increment, ValidationMode=mode);
end
