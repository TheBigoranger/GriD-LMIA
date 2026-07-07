function out = uplus(obj)
    %UPLUS Unary plus for a dpmat.
    %
    %   Syntax:
    %     B = +A
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     B = +A;

    out = obj;
end
