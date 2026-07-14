function out = vec(obj)
    %VEC Vectorize each coefficient payload of a pdvar expression.
    %
    %   Syntax:
    %     v = vec(P)
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "full");
    %     v = vec(P);

    out = unOp(obj, @(a) a(:), [prod(obj.MatrixSize), 1]);
end
