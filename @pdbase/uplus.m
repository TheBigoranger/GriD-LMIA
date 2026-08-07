function out = uplus(obj)
    %UPLUS Unary plus for a pdbase-derived matrix payload.
    %
    %   Syntax:
    %     out = +obj
    %
    %   Output:
    %     out - The input object unchanged.
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [1 1], 0);
    %     out = +obj;

    out = obj;
end
