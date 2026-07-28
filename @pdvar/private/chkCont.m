function tf = chkCont(vals, nCell, degree)
    %CHKCONT Classify complete shared-face continuity of affine coefficients.

    nPar = numel(nCell);
    cells = helper.combRows(arrayfun(@(n) 1:n, nCell, ...
        "UniformOutput", false));
    labels = helper.combRows(repmat({0:degree}, 1, nPar));
    tf = true;

    for dim = 1:nPar
        upper = find(labels(:, dim) == degree);
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
    tolerance = 1e-9 * max([1, norm(lhs, 'fro'), norm(rhs, 'fro')]);
    tf = norm(difference, 'fro') <= tolerance;
end
