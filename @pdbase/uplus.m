function out = uplus(obj)
    %UPLUS Unary plus for a pdbase-derived matrix payload.
    %
    %   Syntax:
    %     out = +obj
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [1 1], 0);
    %     out = +obj;

    out = obj;
end
