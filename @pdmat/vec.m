function out = vec(obj)
    %VEC Vectorize each coefficient payload of a coefficient-backed pdmat.
    %
    %   Syntax:
    %     v = vec(A)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    %     v = vec(A);

    out = unOp(obj, @(a) a(:));
end
