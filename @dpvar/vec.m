function out = vec(obj)
    %VEC Vectorize each coefficient payload of a dpvar expression.
    %
    %   Syntax:
    %     v = vec(P)
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "full");
    %     v = vec(P);

    out = unOp(obj, @(a) a(:), [prod(obj.MatrixSize), 1]);
end
