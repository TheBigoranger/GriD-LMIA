function out = flipud(obj)
    %FLIPUD Flip each pdvar coefficient payload up to down.
    %
    %   Syntax:
    %     Q = flipud(P)
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "full");
    %     Q = flipud(P);

    out = unOp(obj, @(a) flipud(a));
end
