function out = trace(obj)
    %TRACE Sum the main diagonal of each pdvar coefficient payload.
    %
    %   Syntax:
    %     t = trace(P)
    %
    %   Example:
    %     P = pdvar(2, {[0 1]});
    %     t = trace(P);

    out = unOp(obj, @(a) trace(a), [1 1]);
end
