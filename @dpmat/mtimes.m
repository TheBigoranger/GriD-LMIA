function out = mtimes(lhs, rhs)
%MTIMES Matrix product for coefficient-backed dpmat operands.
%
%   Syntax:
%     C = A * B
%     C = A * M
%     C = M * A
%
%   Example:
%     A = dpmat({[0 1]}, {[1 0; 0 1], [2 0; 0 2]}, Degree=1);
%     C = A * 2;

if isa(lhs, "dpmat")
    anchor = lhs;
else
    anchor = rhs;
end
if isa(lhs, "dpmat") && isZeroObj(lhs) && isa(rhs, "dpmat")
    grid = lhs.mergeGrid("dpmat:MixedGrid", lhs, rhs);
    out = zeroObj(grid, zeroProdSize(lhs.MatrixSize, rhs.MatrixSize, ...
        "dpmat:InvalidMultiplication"));
    return
end
if isa(lhs, "dpmat") && isa(rhs, "dpmat") && isZeroObj(rhs)
    grid = lhs.mergeGrid("dpmat:MixedGrid", lhs, rhs);
    out = zeroObj(grid, zeroProdSize(lhs.MatrixSize, rhs.MatrixSize, ...
        "dpmat:InvalidMultiplication"));
    return
end
if isa(lhs, "dpmat") && isZeroNum(rhs)
    out = zeroObj(lhs.GridInfo.Vectors, zeroProdSize(lhs.MatrixSize, size(rhs), ...
        "dpmat:InvalidMultiplication"));
    return
end
if isZeroNum(lhs) && isa(rhs, "dpmat")
    out = zeroObj(rhs.GridInfo.Vectors, zeroProdSize(size(lhs), rhs.MatrixSize, ...
        "dpmat:InvalidMultiplication"));
    return
end
if isa(lhs, "dpmat") && isnumeric(rhs) && isscalar(rhs) && ...
        isreal(rhs) && isfinite(rhs)
    out = unOp(lhs, @(a) a * rhs);
    return
end
if isnumeric(lhs) && isscalar(lhs) && isreal(lhs) && ...
        isfinite(lhs) && isa(rhs, "dpmat")
    out = unOp(rhs, @(a) lhs * a);
    return
end

grid = anchor.mergeGrid("dpmat:MixedGrid", lhs, rhs);
ld = asData(grid, lhs, [], "dpmat:InvalidMultiplication");
rd = asData(grid, rhs, [], "dpmat:InvalidMultiplication");
if ld.MatrixSize(2) ~= rd.MatrixSize(1)
    error("dpmat:InvalidMultiplication", ...
        "Inner matrix dimensions must agree for dpmat multiplication.");
end

nCell = cellfun(@numel, grid) - 1;
vals = helper.mkNest(nCell, @(subs) anchor.bernProd( ...
    helper.cellGet(ld.LocalValues, subs), ld.Degree, ...
    helper.cellGet(rd.LocalValues, subs), rd.Degree));

if isZeroVals(vals)
    out = zeroObj(grid, zeroProdSize(ld.MatrixSize, rd.MatrixSize, ...
        "dpmat:InvalidMultiplication"));
    return
end

out = dpmat(grid, vals, Degree=ld.Degree + rd.Degree);
end

function sz = zeroProdSize(lhs, rhs, errId)
    lhsScalar = isequal(lhs, [1 1]);
    rhsScalar = isequal(rhs, [1 1]);
    if lhsScalar
        sz = rhs;
        return
    end
    if rhsScalar
        sz = lhs;
        return
    end
    if lhs(2) ~= rhs(1)
        error(errId, "Inner matrix dimensions must agree for dpmat multiplication.");
    end
    sz = [lhs(1), rhs(2)];
end
