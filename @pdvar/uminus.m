function out = uminus(obj)
    %UMINUS Negate a pdvar coefficient expression.
    %
    %   Syntax:
    %     Q = -P
    %
    %   Example:
    %     P = pdvar(2, {[0 1]});
    %     Q = -P;

    out = unOp(obj, @(a) -a);
end
