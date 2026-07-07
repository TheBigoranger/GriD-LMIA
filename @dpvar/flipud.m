function out = flipud(obj)
    %FLIPUD Flip each dpvar coefficient payload up to down.
    %
    %   Syntax:
    %     Q = flipud(P)
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "full");
    %     Q = flipud(P);

    out = unOp(obj, @(a) flipud(a));
end
