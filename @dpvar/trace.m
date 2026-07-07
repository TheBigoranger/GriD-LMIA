function out = trace(obj)
    %TRACE Sum the main diagonal of each dpvar coefficient payload.
    %
    %   Syntax:
    %     t = trace(P)
    %
    %   Example:
    %     P = dpvar(2, {[0 1]});
    %     t = trace(P);

    out = unOp(obj, @(a) trace(a), [1 1]);
end
