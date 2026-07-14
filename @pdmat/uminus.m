function out = uminus(obj)
    %UMINUS Negate a coefficient-backed pdmat.
    %
    %   Syntax:
    %     B = -A
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     B = -A;

    out = unOp(obj, @(a) -a);
end
