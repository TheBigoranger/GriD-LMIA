function out = fliplr(obj)
    %FLIPLR Flip each pdvar coefficient payload left to right.
    %
    %   Syntax:
    %     Q = fliplr(P)
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "full");
    %     Q = fliplr(P);

    out = unOp(obj, @(a) fliplr(a));
end
