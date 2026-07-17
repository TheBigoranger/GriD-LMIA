function out = applyPolya(obj, degreeIncrement)
    %APPLYPOLYA Rebuild this residual with a selected Pólya degree increment.
    %
    %   Syntax:
    %     out = obj.applyPolya()
    %     out = obj.applyPolya(degreeIncrement)
    %
    %   Arguments:
    %     degreeIncrement - Optional nonnegative elevation increment; default 1.
    %
    %   Output:
    %     out - New pdlmi rebuilt with Pólya elevation enabled.
    %
    %   The no-argument form uses increment one. Passing a finite nonnegative
    %   integer replaces any prior selection because assembly always starts
    %   from the stored original Residual rather than existing constraints.
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
    if nargin < 2
        degreeIncrement = 1;
    end
    degreeIncrement = double(helper.chk(degreeIncrement, ...
        "pdlmi:InvalidPolyaDegree", ...
        "PolyaDegree must be a finite nonnegative integer scalar.", ...
        "numeric", "real", "finite", "integer", "nonnegative", "scalar"));
    out = pdlmi(obj.Residual, obj.Relation, UsePolya=true, ...
        PolyaDegree=degreeIncrement);
end
