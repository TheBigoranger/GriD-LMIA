function tf = eq(lhs, rhs)
    %EQ True when two pdmat objects have a zero coefficient difference.
    %
    %   Syntax:
    %     tf = A == B
    %
    %   Output:
    %     tf - Scalar logical reporting whether A - B is provably zero.
    %
    %   Both operands must be pdmat objects. Mixed pdmat/pdvar equality
    %   remains owned by pdvar, which is method-superior to pdmat.
    %
    %   Example:
    %     A = pdmat([0 1], {1, 2}, Degree=1);
    %     B = pdmat([0 1], {1, 2}, Degree=1);
    %     tf = A == B;

    if ~(isa(lhs, "pdmat") && isa(rhs, "pdmat"))
        error("pdmat:InvalidEquality", ...
            "pdmat equality requires pdmat operands on both sides.");
    end

    % Subtraction owns compatibility checks and representation alignment.
    tf = helper.isZero(lhs - rhs, "obj");
end
