function out = trace(obj)
    %TRACE Sum the main diagonal of every stored coefficient matrix.
    %
    %   Syntax:
    %     out = trace(obj)
    %
    %   Output:
    %     out - Same dynamic class with scalar trace coefficients.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {eye(2), 2*eye(2)}, Degree=1);
    %     t = trace(A);

    out = mapUnary(obj, @diagSum, [1 1]);
end

function val = diagSum(val)
    %DIAGSUM Sum only the main matrix diagonal, including for vector inputs.
    [m, n] = size(val);
    idx = 1:(m + 1):(1 + (min(m, n) - 1) * (m + 1));
    val = sum(val(idx));
end
