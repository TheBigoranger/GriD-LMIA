function out = ge(lhs, rhs)
    %GE Build a nonnegative coefficient certificate for known pdmat data.
    %
    %   Syntax:
    %     C = A >= B
    %     C = A >= M
    %
    %   Numeric and pdmat operands form a known residual. The returned pdlmi
    %   uses Direct by default; failed numeric certificates are inconclusive.
    %
    %   Example:
    %     A = pdmat([0 1], {1, 2}, Degree=1);
    %     C = A >= 0;

    out = pdlmi(lhs - rhs, ">=");
end
