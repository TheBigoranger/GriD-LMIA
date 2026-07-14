function out = uplus(obj)
    %UPLUS Unary plus for a pdmat.
    %
    %   Syntax:
    %     B = +A
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     B = +A;

    out = obj;
end
