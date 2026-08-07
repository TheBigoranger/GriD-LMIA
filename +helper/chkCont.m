function tf = chkCont(vals, nCell, degree)
    %CHKCONT Classify continuity across every shared physical-cell face.
    %
    %   Syntax:
    %     tf = helper.chkCont(vals, nCell, degree)
    %
    %   Arguments:
    %     vals   - Nested coefficient tree with one or more rows per leaf.
    %     nCell  - 1-by-ell physical-cell count.
    %     degree - 1-by-ell local Bernstein degree.
    %
    %   Output:
    %     tf - True when every neighboring shared face has matching boundary
    %          coefficients; false at the first detected mismatch.
    %
    %   Example:
    %     tf = helper.chkCont(obj.LocalValues, obj.GridInfo.NumNodes - 1, ...
    %         obj.Degree);
    %
    %   Continuity is metadata, not a numerical repair step. This helper only
    %   compares existing face coefficients so constructors and internal
    %   rewraps can decide whether they may claim IsContinuous.
    nPar = numel(nCell);
    cells = helper.combRows(arrayfun(@(n) 1:n, nCell, ...
        "UniformOutput", false));
    labels = helper.combRows(arrayfun(@(d) 0:d, degree, ...
        "UniformOutput", false));
    tf = true;
    for dim = 1:nPar
        upper = find(labels(:, dim) == degree(dim));
        lower = find(labels(:, dim) == 0);
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
                for q = 1:numel(upper)
                    if ~sameMat(lhs{row, upper(q)}, rhs{row, lower(q)})
                        tf = false;
                        return
                    end
                end
            end
        end
    end
end

function tf = sameMat(lhs, rhs)
    %SAMEMAT Compare numeric faces tolerantly and affine faces exactly.
    if isa(lhs, "sdpvar") || isa(rhs, "sdpvar")
        difference = lhs - rhs;
        if isa(difference, "sdpvar")
            tf = all(full(getbase(difference)) == 0, "all");
        else
            tf = isnumeric(difference) && all(difference == 0, "all");
        end
        return
    end
    difference = lhs - rhs;
    tol = 1e-9 * max([1, norm(lhs, 'fro'), norm(rhs, 'fro')]);
    tf = norm(difference, 'fro') <= tol;
end
