function out = applyPolya(obj, degreeIncrement)
    %APPLYPOLYA Rebuild this residual with a selected Pólya degree increment.
    %
    %   Syntax:
    %     out = obj.applyPolya()
    %     out = obj.applyPolya(degreeIncrement)
    %
    %   The no-argument form uses increment one. Passing a finite nonnegative
    %   integer replaces any prior selection because assembly always starts
    %   from the stored original Residual rather than existing constraints.
    %   This value-class method returns a new dplmi and leaves obj unchanged;
    %   invalid increments raise dplmi:InvalidPolyaDegree.
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "symmetric");
    %     direct = P >= 0;
    %     polya = direct.applyPolya(2);

    if nargin < 2
        degreeIncrement = 1;
    end
    degreeIncrement = double(helper.chk(degreeIncrement, ...
        "dplmi:InvalidPolyaDegree", ...
        "PolyaDegree must be a finite nonnegative integer scalar.", ...
        "numeric", "real", "finite", "integer", "nonnegative", "scalar"));
    out = dplmi(obj.Residual, obj.Relation, UsePolya=true, ...
        PolyaDegree=degreeIncrement);
end
