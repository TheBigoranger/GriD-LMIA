function tests = test_rhodiff
    % Behavioral regressions for pdvar.rhodiff.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function test_scalar_degree_derivatives_become_degree_zero(testCase)
    % Scalar degree-one derivatives should become degree-zero rate rows.
    P = pdvar(1, {[0 2]});
    cp = P.coeffs(1);

    D = rhodiff(P, [-2 3]);
    cd = D.coeffs(1);

    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyEqual(D.ncoeff(), 1);
    testCase.verifyEqual(D.Continuity, Inf);
    testCase.verifyTrue(D.IsContinuous);
    testCase.verifyEqual(D.RateBounds, [-2 3]);
    testCase.verifyEqual(D.SourceSummary, "derivative");
    verifyCoeffTable(testCase, cd, {
        -2 * (cp{2} - cp{1}) / 2
        3 * (cp{2} - cp{1}) / 2
    });
end

function test_constructor_created_scalar_quadratics_drop_degree(testCase)
    % Constructor-created scalar quadratics drop to degree-one derivatives.
    C = pdvar(1, {[0 1]}, Degree=2);
    cc = C.coeffs(1);

    D = rhodiff(C, [-1 2]);

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyEqual(D.Degree, 1);
    verifyCoeffTable(testCase, D.coeffs(1), {
        -2 * (cc{2} - cc{1}), -2 * (cc{3} - cc{2})
        4 * (cc{2} - cc{1}), 4 * (cc{3} - cc{2})
    });
end

function test_tensor_derivatives_degree_combrows_rate_vertex(testCase)
    % Tensor derivatives should keep degree one and combRows rate-vertex order.
    grid = {[0 2], [10 20]};
    rb = [-1 2; -3 5];
    P = pdvar(1, grid);
    cp = P.coeffs([1 1]);

    D = rhodiff(P, rb);
    cd = D.coeffs([1 1]);

    testCase.verifyEqual(D.Degree, [1 1]);
    testCase.verifyEqual(D.ncoeff(), 4);
    testCase.verifyEqual(size(cd), [4 4]);

    a0 = (cp{3} - cp{1}) / 2;
    a1 = (cp{4} - cp{2}) / 2;
    b0 = (cp{2} - cp{1}) / 10;
    b1 = (cp{4} - cp{3}) / 10;
    verts = [
        -1 -3
        -1 5
        2 -3
        2 5
    ];
    exp = cell(4, 4);
    for row = 1:4
        v = verts(row, :);
        exp(row, :) = {
            v(1) * a0 + v(2) * b0, ...
            v(1) * a1 + v(2) * b0, ...
            v(1) * a0 + v(2) * b1, ...
            v(1) * a1 + v(2) * b1
        };
    end
    verifyCoeffTable(testCase, cd, exp);
end

function test_constructor_created_tensor_quadratics_elevate(testCase)
    % Constructor-created tensor quadratics elevate partials to common degree.
    grid = {[0 2], [10 14]};
    rb = [-1 2; -3 5];
    C = pdvar(1, grid, Degree=[2 2]);
    cc = C.coeffs([1 1]);

    D = rhodiff(C, rb);
    cd = D.coeffs([1 1]);

    verts = [
        -1 -3
        -1 5
        2 -3
        2 5
    ];
    exp = cell(4, 9);
    for row = 1:4
        exp(row, :) = tensorDiffExpected(cc, [2 2], ...
            [2 4], verts(row, :), [1 1]);
    end
    testCase.verifyEqual(C.Degree, [2 2]);
    testCase.verifyEqual(D.Degree, [2 2]);
    verifyCoeffTable(testCase, cd, exp);
end

function test_unequal_zero_direction_degrees_common_tensor(testCase)
    % Unequal and zero direction degrees retain one common tensor basis.
    grid = {[0 2], [10 14]};
    rb = [-1 2; -3 5];
    P = pdvar(1, grid, Degree=[1 2]);
    beforeVars = objectVariables(P);
    cp = P.coeffs([1 1]);

    D = rhodiff(P, rb);
    verts = rateVertsExpected(rb);
    expected = cell(4, 6);
    for row = 1:4
        expected(row, :) = tensorDiffExpected(cp, [1 2], ...
            [2 4], verts(row, :), [1 1]);
    end
    testCase.verifyEqual(D.Degree, [1 2]);
    testCase.verifySize(D.coeffs([1 1]), [4 6]);
    testCase.verifyEqual(D.Continuity, [Inf Inf]);
    testCase.verifyTrue(D.IsContinuous);
    testCase.verifyEqual(D.RateBounds, rb);
    testCase.verifyEqual(objectVariables(D), beforeVars);
    verifyCoeffTable(testCase, D.coeffs([1 1]), expected);

    Q = pdvar(1, grid, Degree=[0 2]);
    qVars = objectVariables(Q);
    cq = Q.coeffs([1 1]);
    E = rhodiff(Q, rb);
    zeroAxisExpected = cell(4, 3);
    for row = 1:4
        zeroAxisExpected(row, :) = tensorDiffExpected(cq, [0 2], ...
            [2 4], verts(row, :), [1 1]);
    end
    testCase.verifyEqual(E.Degree, [0 2]);
    testCase.verifyEqual(objectVariables(E), qVars);
    verifyCoeffTable(testCase, E.coeffs([1 1]), zeroAxisExpected);
end

function test_tensor_plans_preserve_later_cells_and_matrix_shapes(testCase)
    % Shared plans must not retain first-cell symbols, widths or matrix shape.
    grid = {[0 1 3], [-2 0 5]};
    rb = [-1 2; -3 5];
    verts = rateVertsExpected(rb);
    for shape = {[2 3], [3 2]}
        sz = shape{1};
        P = pdvar(sz(1), sz(2), grid, 'full', Degree=[1 2]);
        D = rhodiff(P, rb);
        for i = 1:2
            for j = 1:2
                widths = [diff(grid{1}(i:i+1)), diff(grid{2}(j:j+1))];
                source = P.coeffs([i j]);
                expected = cell(4,6);
                for row = 1:4
                    expected(row,:) = tensorDiffExpected(source,[1 2], ...
                        widths,verts(row,:),sz);
                end
                verifyCoeffTable(testCase,D.coeffs([i j]),expected);
            end
        end
        testCase.verifyEqual(D.MatrixSize,sz);
        testCase.verifyEqual(D.Degree,[1 2]);
        testCase.verifyEqual(objectVariables(D),objectVariables(P));
    end
end

function test_rectangular_zero_axis_mixed_rates_use_exact_derivative_oracle(testCase)
    % The fixed first rate has no derivative contribution on a zero-degree axis.
    rb = [3 3;-2 5];
    P = pdvar(2,3,{[0 2 5],[-3 1 6]},'full',Degree=[0 2],RateBounds=rb);
    D = tests.infrastructure.verify_tensor_diff(testCase,P,rb,true);
    testCase.verifyEqual(D.NumRateRows,2);
    for subs = [1 1;1 2;2 1;2 2]'
        c = D.coeffs(subs');
        for k = 1:3
            tests.infrastructure.verify_expr(testCase,5*c{1,k},-2*c{2,k});
        end
    end
end

function test_constant_tensor_has_zero_coefficient_rate(testCase)
    % A constant tensor has one zero coefficient for every rate-box vertex.
    P = pdvar(1, {[0 1 2], [10 20]}, Degree=[0 0]);
    D = rhodiff(P, [-1 2; -3 5]);

    testCase.verifyEqual(D.Degree, [0 0]);
    testCase.verifyFalse(D.ContainsDecision);
    testCase.verifyEqual(D.Continuity, [Inf Inf]);
    testCase.verifyTrue(D.IsContinuous);
    testCase.verifySize(D.coeffs([1 1]), [4 1]);
    testCase.verifySize(D.coeffs([2 1]), [4 1]);
    verifyCoeffTable(testCase, D.coeffs([1 1]), {0; 0; 0; 0});
    verifyCoeffTable(testCase, D.coeffs([2 1]), {0; 0; 0; 0});
end

function test_rhodiff_object_ratebounds_or_reject_incompatible(testCase)
    % rhodiff should use object RateBounds or reject incompatible bounds.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    Q = pdvar(1, {[0 1]});

    D = rhodiff(P);

    testCase.verifyEqual(D.RateBounds, [-1 1]);
    testCase.verifyError(@() rhodiff(Q), "pdvar:MissingRateBounds");
    testCase.verifyError(@() rhodiff(P, [0 1]), "pdvar:RateBoundsMismatch");
    testCase.verifyError(@() rhodiff(Q, [0 1; -1 1]), "pdvar:InvalidRateBounds");
end

function test_rate_vertex_expressions_terminal_until_quadratic(testCase)
    % Rate-vertex expressions are terminal until quadratic-rate algebra exists.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    D = rhodiff(P);

    testCase.verifyError(@() rhodiff(D), "pdvar:InvalidDiff");
    testCase.verifyError(@() rhodiff(D, [-1 1]), "pdvar:InvalidDiff");
end

function test_fixed_rate_produces_row_while_derivative(testCase)
    % A fixed rate produces one row while derivative cells remain independent.
    P = pdvar(1, {[0 1 3]}, RateBounds=[1 1]);
    cp1 = P.coeffs(1);
    cp2 = P.coeffs(2);

    D = rhodiff(P);
    left = D.coeffs(1);
    right = D.coeffs(2);

    verifyCoeffTable(testCase, left, {cp1{2} - cp1{1}});
    verifyCoeffTable(testCase, right, {(cp2{2} - cp2{1}) / 2});
    testCase.verifyFalse(isequal(getvariables(left{1, 1}), getvariables(right{1, 1})));

    tbl = D.bernTable();
    testCase.verifyTrue(ismember("RateVertex", string(tbl.Properties.VariableNames)));
    testCase.verifyEqual(vertcat(tbl.RateVertex{:}), [1; 1]);
    testCase.verifyError(@() rhodiff(D), "pdvar:InvalidDiff");

    shifted = D + 1;
    sliced = D(1, 1);
    testCase.verifyEqual(shifted.NumRateRows, 1);
    testCase.verifyEqual(sliced.NumRateRows, 1);
    testCase.verifyEqual(size(shifted.coeffs(1), 1), 1);
end

function test_degree_zero_rate_dependent_expressions_differentiate(testCase)
    % Degree-zero rate-dependent expressions should differentiate to zero.
    x = sdpvar(1, 1);
    vals = {{x}};
    init = struct( ...
        "PdvarInternal", true, ...
        "Grid", {{[0 1]}}, ...
        "MatrixSize", [1 1], ...
        "Degree", 0, ...
        "LocalValues", {vals}, ...
        "IsContinuous", true, ...
        "ContainsDecision", true, ...
        "RateBounds", [-1 1], ...
        "SourceSummary", "test-degree-zero");
    P = pdvar(init);

    D = rhodiff(P);

    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyFalse(D.ContainsDecision);
    verifyCoeffTable(testCase, D.coeffs(1), {0; 0});
end

function test_affine_algebra_broadcast_ordinary_coefficients(testCase)
    % Affine algebra should broadcast ordinary coefficients across rate rows.
    P = pdvar(1, {[0 1]});
    cp = P.coeffs(1);
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);
    X = sdpvar(1, 1);
    A = pdmat({[0 1]}, {10, 20}, Degree=1);

    S = D + P;
    R = P - D;
    E = D + X;
    K = D + A;

    testCase.verifyEqual(S.Continuity, Inf);
    testCase.verifyTrue(S.IsContinuous);
    verifyCoeffTable(testCase, S.coeffs(1), {
        cd{1, 1} + cp{1}, cd{1, 1} + cp{2}
        cd{2, 1} + cp{1}, cd{2, 1} + cp{2}
    });
    verifyCoeffTable(testCase, R.coeffs(1), {
        cp{1} - cd{1, 1}, cp{2} - cd{1, 1}
        cp{1} - cd{2, 1}, cp{2} - cd{2, 1}
    });
    verifyCoeffTable(testCase, E.coeffs(1), {
        cd{1, 1} + X
        cd{2, 1} + X
    });
    verifyCoeffTable(testCase, K.coeffs(1), {
        cd{1, 1} + 10, cd{1, 1} + 20
        cd{2, 1} + 10, cd{2, 1} + 20
    });
end

function test_matching_rate_vertex_tables_combine_row(testCase)
    % Matching rate-vertex tables should combine row-wise without broadcasting.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 2]);
    Q = pdvar(1, {[0 1]}, RateBounds=[-1 2]);
    Dp = rhodiff(P);
    Dq = rhodiff(Q);
    cp = Dp.coeffs(1);
    cq = Dq.coeffs(1);

    S = Dp + Dq;
    R = Dp - Dq;

    testCase.verifyEqual(S.Continuity, Inf);
    testCase.verifyTrue(S.IsContinuous);
    testCase.verifyEqual(S.RateBounds, [-1 2]);
    verifyCoeffTable(testCase, S.coeffs(1), {
        cp{1, 1} + cq{1, 1}
        cp{2, 1} + cq{2, 1}
    });
    verifyCoeffTable(testCase, R.coeffs(1), {
        cp{1, 1} - cq{1, 1}
        cp{2, 1} - cq{2, 1}
    });
end

function test_known_data_products_multiply_each_derivative(testCase)
    % Known-data products should multiply each derivative rate row.
    P = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);
    A = pdmat({[0 1]}, {10, 20}, Degree=1);

    L = A * D;
    R = D * A;
    S = 3 * D;

    verifyCoeffTable(testCase, L.coeffs(1), {
        10 * cd{1, 1}, 20 * cd{1, 1}
        10 * cd{2, 1}, 20 * cd{2, 1}
    });
    verifyCoeffTable(testCase, R.coeffs(1), {
        cd{1, 1} * 10, cd{1, 1} * 20
        cd{2, 1} * 10, cd{2, 1} * 20
    });
    verifyCoeffTable(testCase, S.coeffs(1), {3 * cd{1, 1}; 3 * cd{2, 1}});
end

function test_numeric_products_preserve_metadata_only_bounds(testCase)
    % Numeric products preserve metadata-only bounds while active rows stay safe.
    V = pdvar(2, 1, {[0 1]}, "full");
    D = rhodiff(V, [-1 1]);
    cd = D.coeffs(1);
    P = pdvar(2, 1, {[0 1]}, "full");
    R = pdvar(1, {[0 1]}, RateBounds=[-1 1]);

    L = [1 2] * D;
    M = D * [4 5];
    T = R * 2;

    verifyCoeffTable(testCase, L.coeffs(1), {
        [1 2] * cd{1, 1}
        [1 2] * cd{2, 1}
    });
    verifyCoeffTable(testCase, M.coeffs(1), {
        cd{1, 1} * [4 5]
        cd{2, 1} * [4 5]
    });
    testCase.verifyEqual(T.RateBounds, [-1 1]);
    testCase.verifyEqual(T.NumRateRows, 0);
    testCase.verifyEqual(objectVariables(T), objectVariables(R));
    testCase.verifyError(@() D * D, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() D * P, "pdvar:InvalidMultiplication");
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

function verifyCoeffTable(testCase, actual, expected)
    % Rate-vertex coefficient tables should match expected shape and entries.
    testCase.verifyEqual(size(actual), size(expected));
    for row = 1:size(expected, 1)
        for col = 1:size(expected, 2)
            verifyExpr(testCase, actual{row, col}, expected{row, col});
        end
    end
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

function verifyExpr(testCase, actual, expected)
    % Compare numeric or affine coefficient expressions without solving them.
    diffVal = actual - expected;
    if isa(diffVal, "sdpvar")
        base = full(getbase(diffVal));
        testCase.verifyEqual(base, zeros(size(base)), AbsTol=1e-10);
    else
        testCase.verifyEqual(diffVal, zeros(size(diffVal)), AbsTol=1e-10);
    end
end
function test_unequal_cell_widths_and_rate_signs(testCase)
    A = tests.infrastructure.fixture("pdvar", false);
    D = rhodiff(A);
    widths = [2 3];
    rates = [-2 3];
    for cellIndex = 1:2
        input = A.coeffs(cellIndex);
        expected = cell(2,2);
        for row = 1:2
            for k = 1:2
                expected{row,k} = rates(row)*2/widths(cellIndex)*(input{k+1}-input{k});
            end
        end
        tests.infrastructure.verify_expr(testCase, D.coeffs(cellIndex), expected);
    end
    testCase.verifyEqual(D.Degree, 1);
    testCase.verifyEqual(D.NumRateRows, 2);
    fixedSource = tests.infrastructure.fixture("pdvar", false, [4 4]);
    input = fixedSource.coeffs(2);
    fixed = rhodiff(fixedSource);
    testCase.verifyEqual(fixed.NumRateRows, 1);
    tests.infrastructure.verify_expr(testCase, fixed.coeffs(2), ...
        {8/3*(input{2}-input{1}), 8/3*(input{3}-input{2})});
end

function test_tensor_rate_order(testCase)
    % Dyadic unequal widths retain exact affine-basis comparisons.
    grid = {[0 1 3], [-2 0 4], [10 14]};
    rb = [-2 3; -5 7; -11 13];
    source = pdvar(2, grid, "full", Degree=[2 1 1], RateBounds=rb);
    tests.infrastructure.verify_tensor_diff(testCase, source, rb, true);
end

function test_fixed_tensor_rate_order(testCase)
    % Fixed directions collapse duplicate vertices without moving axes.
    grid = {[0 1 3], [-2 0 4], [10 14]};
    rb = [2 2; -3 5; 7 7];
    source = pdvar(2, grid, "full", Degree=[1 2 1], RateBounds=rb);
    actual = tests.infrastructure.verify_tensor_diff(testCase, source, rb, true);
    testCase.verifyEqual(actual.NumRateRows, 2);
end

function test_directionwise_reduction_zero_rates_and_partial_minima(testCase)
    grid = {[0 1 2], [-2 0 3]};
    P = pdvar(1, grid, Degree=[3 2], Continuity=[2 1]);

    firstOnly = rhodiff(P, [1 1; 0 0]);
    both = rhodiff(P, [1 1; 2 2]);

    testCase.verifyEqual(firstOnly.Continuity, [1 1]);
    testCase.verifyEqual(both.Continuity, [1 0]);
    testCase.verifyEqual(firstOnly.NumRateRows, 1);
    testCase.verifyEqual(both.NumRateRows, 1);
end

function test_three_parameter_rectangular_zero_axis_and_fixed_rates(testCase)
    % Every affine coefficient must retain tensor and collapsed-rate ordering.
    grid = {[0 1 3],[-2 0 4],[10 12 16]};
    rb = [-2 3;7 7;-1 4];
    P = pdvar(2,3,grid,'full',Degree=[2 0 3],RateBounds=rb);
    D = tests.infrastructure.verify_tensor_diff(testCase,P,rb,true);
    testCase.verifyEqual(D.MatrixSize,[2 3]);
    testCase.verifyEqual(D.NumRateRows,4);
end

function test_affine_partial_cancellation_retains_zero_and_nonzero_rate_rows(testCase)
    % Equal partials cancel only at the opposing-rate vertex, in every cell.
    grid = {[0 1 3],[-2 0 4]};
    X = sdpvar(2,3,'full');
    A = pdmat(grid,@(x,y) x+y,Degree=[1 1]);
    P = X*A;
    before = P.LocalValues;
    D = rhodiff(P,[1 1;-1 2]);
    Z = rhodiff(P,[1 1;-1 -1]);
    for subs = P.cells()'
        expected = [repmat({zeros(2,3)},1,4);repmat({3*X},1,4)];
        verifyCoeffTable(testCase,D.coeffs(subs'),expected);
        verifyCoeffTable(testCase,Z.coeffs(subs'),repmat({zeros(2,3)},1,4));
    end
    testCase.verifyEqual(D.NumRateRows,2);
    testCase.verifyEqual(Z.NumRateRows,1);
    testCase.verifyEqual(Z.RateBounds,[1 1;-1 -1]);
    testCase.verifyEqual(Z.Continuity,[Inf Inf]);
    testCase.verifyEqual(Z.Degree,[1 1]);
    testCase.verifyEqual(P.LocalValues,before);
end
