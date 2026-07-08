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

out = dpmat(grid, vals, Degree=ld.Degree + rd.Degree);
end
