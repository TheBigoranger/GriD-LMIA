function out = uminus(obj)
    %UMINUS Negate every coefficient matrix of a pdbase-derived object.
    %
    %   Syntax:
    %     out = -obj
    %
    %   Output:
    %     out - Same dynamic class with every stored coefficient negated.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     B = -A;

    out = mapUnary(obj, @(a) -a);
end
