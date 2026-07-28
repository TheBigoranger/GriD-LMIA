function tf = eq(lhs, rhs)
    %EQ True when two pdmat objects have a zero coefficient difference.
    %
    %   Syntax:
    %     tf = A == B
    %
    %   Output:
    %     tf - Scalar logical reporting whether A - B is provably zero.
    %
    %   One operand must be pdmat. The other may be pdmat or any finite real
    %   numeric scalar/matrix accepted by subtraction. Mixed pdmat/pdvar
    %   equality remains owned by method-superior pdvar.
    %
    %   Example:
    %     A = pdmat([0 1], {1, 2}, Degree=1);
    %     B = pdmat([0 1], {1, 2}, Degree=1);
    %     tf = A == B;

    lhsOk = isa(lhs, "pdmat") || isnumeric(lhs);
    rhsOk = isa(rhs, "pdmat") || isnumeric(rhs);
    if ~(lhsOk && rhsOk && (isa(lhs, "pdmat") || isa(rhs, "pdmat")))
        error("pdmat:InvalidEquality", ...
            "pdmat equality requires one pdmat operand and one pdmat or numeric operand.");
    end

    % Subtraction owns numeric promotion, compatibility checks, and alignment.
    tf = helper.isZero(lhs - rhs, "obj");
end
