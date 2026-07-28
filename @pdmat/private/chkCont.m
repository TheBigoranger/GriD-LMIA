function tf = chkCont(vals, nCell, deg)
    %CHKCONT Check that adjacent local Bernstein faces agree.
    %
    %   Syntax:
    %     tf = chkCont(localValues, numCells, degree)
    %
    %   Arguments:
    %     localValues - Nested physical-cell coefficient tree.
    %     numCells   - Physical-cell count per parameter direction.
    %     degree     - Scalar Bernstein degree.
    %
    %   Output:
    %     tf - True when every adjacent face agrees within tolerance.
    %
    %   Adjacent hypercubes must use matching endpoint coefficients on every
    %   shared face for explicit nested LocalValues to be continuous. This
    %   helper only classifies the data; the public constructor owns warnings.

    nPar = numel(nCell);
    cells = helper.combRows(arrayfun(@(n) 1:n, nCell, "UniformOutput", false));
    lbls = helper.combRows(repmat({0:deg}, 1, nPar));
    tf = true;

    for dim = 1:nPar
        % Label degree is the upper face; label zero is the neighbor's lower face.
        hi = find(lbls(:, dim) == deg);
        lo = find(lbls(:, dim) == 0);
        step = zeros(1, nPar);
        step(dim) = 1;
        for k = 1:size(cells, 1)
            subs = cells(k, :);
            if subs(dim) == nCell(dim)
                continue
            end
            lhs = helper.cellGet(vals, subs);
            rhs = helper.cellGet(vals, subs + step);
            for row = 1:size(lhs, 1)
                for q = 1:numel(hi)
                    if ~sameMat(lhs{row, hi(q)}, rhs{row, lo(q)})
                        tf = false;
                        return
                    end
                end
            end
        end
    end
end

function tf = sameMat(lhs, rhs)
    %SAMEMAT Use the package's scale-aware Bernstein comparison tolerance.
    tol = 1e-9 * max([1, norm(lhs, "fro"), norm(rhs, "fro")]);
    tf = norm(lhs - rhs, "fro") <= tol;
end
