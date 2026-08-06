function out = applyPolya(obj, varargin)
    %APPLYPOLYA Rebuild this residual with a selected Pólya degree increment.
    %
    %   Syntax:
    %     out = obj.applyPolya()
    %     out = obj.applyPolya(degreeIncrement)
    %
    %   Arguments:
    %     degreeIncrement - Optional scalar or ell-element increment; default 1.
    %
    %   Output:
    %     out - New pdlmi rebuilt with Pólya elevation enabled.
    %
    %   The no-argument form uses ones(1,ell). A scalar expands uniformly; an
    %   ell-element vector elevates componentwise. Either form replaces any
    %   prior Pólya, Putinar, SparsePutinar, sparse full-box, or FullBox
    %   selection because assembly always starts from the stored original
    %   Residual rather than existing constraints.
    %   This value-class method returns a new pdlmi and leaves obj unchanged;
    %   entry-wise inequalities vectorize every elevated matrix coefficient.
    %   Invalid increments raise pdlmi:InvalidPolyaDegree. Coefficient equality
    %   raises pdlmi:UnsupportedEqualityCertificate before increment validation.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric");
    %     direct = P >= 0;
    %     polya = direct.applyPolya(2);

    if obj.Relation == "=="
        error("pdlmi:UnsupportedEqualityCertificate", ...
            "Coefficient equality supports direct assembly only.");
    end
    [args, validationMode] = parseApplyValidation(varargin);
    if numel(args) > 1
        error("pdlmi:InvalidApplyOptions", ...
            "Too many positional inputs were supplied.");
    end
    if isempty(args)
        degreeIncrement = 1;
    else
        degreeIncrement = args{1};
    end
    degreeIncrement = helper.normalizeDegree(degreeIncrement, ...
        obj.Residual.npar(), "pdlmi:InvalidPolyaDegree", "PolyaDegree");
    out = pdlmi(obj.Residual, obj.Relation, UsePolya=true, ...
        PolyaDegree=degreeIncrement, ValidationMode=validationMode);
end
