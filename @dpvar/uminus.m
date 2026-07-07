function out = uminus(obj)
    %UMINUS Negate a dpvar coefficient expression.
    %
    %   Syntax:
    %     Q = -P
    %
    %   Example:
    %     P = dpvar(2, {[0 1]});
    %     Q = -P;

    out = unOp(obj, @(a) -a);
end
