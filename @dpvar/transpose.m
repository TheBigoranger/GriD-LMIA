function out = transpose(obj)
    %TRANSPOSE Transpose each coefficient payload of a dpvar expression.
    %
    %   Syntax:
    %     Q = P.'
    %
    %   Example:
    %     P = dpvar(2, 3, {[0 1]});
    %     Q = P.';

    out = unOp(obj, @(a) a.', fliplr(obj.MatrixSize));
end
