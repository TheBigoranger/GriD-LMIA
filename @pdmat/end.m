function idx = end(obj, k, n)
    %END Last row or column index for pdmat matrix indexing.
    %
    %   Syntax:
    %     B = A(1:end, end)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    %     B = A(:, end);

    if n == 1
        idx = prod(obj.MatrixSize);
    elseif k <= 2
        idx = obj.MatrixSize(k);
    else
        idx = 1;
    end
end
