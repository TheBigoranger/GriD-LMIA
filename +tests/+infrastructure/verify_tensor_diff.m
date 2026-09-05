function out = verify_tensor_diff(testCase, source, rb, exactAffine)
    % Check metadata and every cell/rate-row/coefficient against a local oracle.
    out = rhodiff(source);
    verts = rateVertsExpected(rb);
    cells = source.cells();

    testCase.verifyEqual(out.Degree, source.Degree);
    testCase.verifyEqual(out.RateBounds, rb);
    testCase.verifyEqual(out.NumRateRows, size(verts, 1));
    testCase.verifyFalse(out.IsContinuous);
    testCase.verifyEqual(out.SourceSummary, "derivative");
    if exactAffine
        testCase.verifyEqual(objectVariables(out), objectVariables(source));
    else
        testCase.verifyFalse(out.ContainsDecision);
    end

    for c = 1:size(cells, 1)
        subs = cells(c, :);
        vals = source.coeffs(subs);
        widths = zeros(1, numel(subs));
        for dim = 1:numel(subs)
            grid = source.GridInfo.Vectors{dim};
            widths(dim) = grid(subs(dim) + 1) - grid(subs(dim));
        end
        actual = out.coeffs(subs);
        testCase.verifySize(actual, ...
            [size(verts, 1), prod(source.Degree + 1)]);
        for row = 1:size(verts, 1)
            expected = tensorDiffExpected(vals, source.Degree, ...
                widths, verts(row, :), source.MatrixSize);
            for coeff = 1:numel(expected)
                if exactAffine
                    verifyExprExact(testCase, actual{row, coeff}, ...
                        expected{coeff});
                else
                    testCase.verifyEqual(actual{row, coeff}, ...
                        expected{coeff}, AbsTol=1e-12);
                end
            end
        end
    end
end

function row = tensorDiffExpected(vals, deg, h, rate, sz)
    % Local oracle for rate-weighted tensor derivative coefficients.
    nPar = numel(h);
    deg = reshape(deg, 1, []);
    if isscalar(deg)
        deg = repmat(deg, 1, nPar);
    end
    row = cell(1, prod(deg + 1));
    for dim = find(deg > 0)
        vecs = arrayfun(@(oneDeg) 0:oneDeg, deg, ...
            "UniformOutput", false);
        vecs{dim} = 0:(deg(dim) - 1);
        partLbls = labelRowsExpected(cellfun(@(oneVec) numel(oneVec) - 1, vecs));
        for k = 1:size(partLbls, 1)
            lbl = partLbls(k, :);
            nxt = lbl;
            nxt(dim) = nxt(dim) + 1;
            base = (vals{lblIdxExpected(nxt, deg)} - vals{lblIdxExpected(lbl, deg)}) ...
                * (deg(dim) * rate(dim) / h(dim));
            for outLabel = lbl(dim):(lbl(dim) + 1)
                out = lbl;
                out(dim) = outLabel;
                idx = lblIdxExpected(out, deg);
                scale = nchoosek(deg(dim) - 1, lbl(dim)) ...
                    * nchoosek(1, outLabel - lbl(dim)) ...
                    / nchoosek(deg(dim), outLabel);
                if isempty(row{idx})
                    row{idx} = base * scale;
                else
                    row{idx} = row{idx} + base * scale;
                end
            end
        end
    end
    for k = 1:numel(row)
        if isempty(row{k})
            row{k} = zeros(sz);
        end
    end
end

function verts = rateVertsExpected(rb)
    % Enumerate distinct rate vertices with the last direction varying fastest.
    choice = rb(1, 1);
    if rb(1, 1) ~= rb(1, 2)
        choice = rb(1, :).';
    end
    verts = choice(:);
    for dim = 2:size(rb, 1)
        choice = rb(dim, 1);
        if rb(dim, 1) ~= rb(dim, 2)
            choice = rb(dim, :).';
        end
        nOld = size(verts, 1);
        verts = [repelem(verts, numel(choice), 1), ...
            repmat(choice(:), nOld, 1)]; %#ok<AGROW>
    end
end

function verifyExprExact(testCase, actual, expected)
    % Affine equivalence requires identical YALMIP variables and bases.
    testCase.verifyEqual(getvariables(actual), getvariables(expected));
    testCase.verifyEqual(full(getbase(actual)), full(getbase(expected)), ...
        AbsTol=0);
end

function vars = objectVariables(obj)
    % Collect all unique YALMIP variables without depending on assignments.
    vars = [];
    cells = obj.cells();
    for k = 1:size(cells, 1)
        coeffs = obj.coeffs(cells(k, :));
        for j = 1:numel(coeffs)
            if isa(coeffs{j}, "sdpvar")
                vars = [vars, getvariables(coeffs{j})]; %#ok<AGROW>
            end
        end
    end
    vars = unique(vars);
end

function idx = lblIdxExpected(lbl, deg)
    mult = fliplr(cumprod([1, fliplr(deg(2:end) + 1)]));
    idx = sum(lbl .* mult) + 1;
end

function rows = labelRowsExpected(deg)
    % Enumerate tensor labels independently of helper.combRows.
    rows = (0:deg(1)).';
    for dim = 2:numel(deg)
        next = (0:deg(dim)).';
        rows = [repelem(rows, numel(next), 1), ...
            repmat(next, size(rows, 1), 1)]; %#ok<AGROW>
    end
end
