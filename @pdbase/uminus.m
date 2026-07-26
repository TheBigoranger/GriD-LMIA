function out = uminus(obj)
    %UMINUS Negate every coefficient matrix of a pdbase-derived object.

    out = unOp(obj, @(a) -a);
end
