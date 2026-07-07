function out = uminus(obj)
    %UMINUS Negate a coefficient-backed dpmat.
    %
    %   Syntax:
    %     B = -A
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     B = -A;

    out = unOp(obj, @(a) -a);
end
