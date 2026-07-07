function idx = end(obj, k, n)
    %END Last row or column index for dpvar matrix indexing.
    %
    %   Syntax:
    %     Q = P(1:end, end)
    %
    %   Example:
    %     P = dpvar(2, 3, {[0 1]}, "full");
    %     q = P(:, end);

    if n == 1
        idx = prod(obj.MatrixSize);
    elseif k <= 2
        idx = obj.MatrixSize(k);
    else
        idx = 1;
    end
end
