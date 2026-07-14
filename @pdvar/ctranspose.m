function out = ctranspose(obj)
    %CTRANSPOSE Conjugate-transpose each coefficient payload of a pdvar expression.
    %
    %   Syntax:
    %     Q = P'
    %
    %   Example:
    %     P = pdvar(2, 3, {[0 1]});
    %     Q = P';

    out = unOp(obj, @(a) a', fliplr(obj.MatrixSize));
end
