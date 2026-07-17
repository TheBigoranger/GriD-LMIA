function out = ge(lhs, rhs)
    %GE Assemble a nonnegative semidefinite or entry-wise constraint.
    %
    %   Syntax:
    %     C = P >= Q
    %     C = P >= 0
    %
    %   A square residual whose coefficients are all Hermitian across every
    %   physical cell and rate row uses semidefinite comparison. Numeric
    %   symmetry uses tolerance 1e-10. Otherwise the entire original residual
    %   is compared entry-wise and pdlmi:ElementwiseInequality is issued once
    %   for the returned pdlmi wrapper. Use C.toYalmip() for YALMIP constraints.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric");
    %     C = P >= 0;

    out = pdlmi(lhs - rhs, ">=");
end
