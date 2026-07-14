function out = trace(obj)
    %TRACE Sum the main diagonal of each coefficient payload.
    %
    %   Syntax:
    %     t = trace(A)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    %     t = trace(A);

    out = unOp(obj, @(a) sum(diag(a)));
end
