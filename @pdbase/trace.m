function out = trace(obj)
    %TRACE Sum the main diagonal of every stored coefficient matrix.

    out = unOp(obj, @diagSum, [1 1]);
end

function val = diagSum(val)
    %DIAGSUM Sum only the main matrix diagonal, including for vector inputs.
    [m, n] = size(val);
    idx = 1:(m + 1):(1 + (min(m, n) - 1) * (m + 1));
    val = sum(val(idx));
end
