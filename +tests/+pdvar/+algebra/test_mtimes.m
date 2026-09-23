function tests = test_mtimes
    % Behavioral regressions for pdvar.mtimes.
    tests = functiontests(localfunctions);
end

function test_cell_varying_constant_factors_preserve_tensor_affine_rate_rows(testCase)
    % Written-order native matrix products are the coefficient oracle.
    grid={[0 1 3],[-2 0 4],[10 14]};
    degree=[0 2 3]; rb=[0 0;-2 3;1 1];
    P=pdvar(2,3,grid,'full',Degree=degree);
    L=pdmat(grid,helper.mkNest([2 2 1], ...
        @(s) {[1+s(1),2;-3,4+s(2)]}),Degree=[0 0 0]);
    R=pdmat(grid,helper.mkNest([2 2 1], ...
        @(s) {[1,2+s(1),-1;3,4,2;0,-2,5+s(2)]}),Degree=[0 0 0]);
    S=pdmat(grid,helper.mkNest([2 2 1], ...
        @(s) {2+s(1)+3*s(2)}),Degree=[0 0 0]);
    sources={P,rhodiff(P,rb)};
    for index=1:numel(sources)
        source=sources{index}; saved=source.LocalValues;
        left=L*source; right=source*R; scaled=S*source;
        testCase.verifyEqual(left.Degree,degree);
        testCase.verifyEqual(right.MatrixSize,[2 3]);
        testCase.verifyEqual(right.NumRateRows,source.NumRateRows);
        testCase.verifyEqual(right.RateBounds,source.RateBounds);
        for subs=source.cells()'
            c=source.coeffs(subs'); l=L.coeffs(subs');
            r=R.coeffs(subs'); s=S.coeffs(subs');
            cl=left.coeffs(subs'); cr=right.coeffs(subs'); cs=scaled.coeffs(subs');
            for coefficient=1:numel(c)
                tests.infrastructure.verify_expr(testCase, ...
                    cl{coefficient},l{1}*c{coefficient});
                tests.infrastructure.verify_expr(testCase, ...
                    cr{coefficient},c{coefficient}*r{1});
                tests.infrastructure.verify_expr(testCase, ...
                    cs{coefficient},s{1}*c{coefficient});
            end
        end
        testCase.verifyEqual(source.LocalValues,saved);
    end
end

function test_zero_fixed_rate_tables_cannot_multiply_each_other(testCase)
    % Zero values do not erase the unsupported product of two active rate tables.
    P = pdvar(2,[0 2 5],'full',Degree=1);
    D = rhodiff(P,[0 0]);
    testCase.verifyEqual(D.NumRateRows,1);
    for cellIndex = 1:2
        tests.infrastructure.verify_expr(testCase,D.coeffs(cellIndex),{zeros(2)});
    end
    testCase.verifyError(@() D*D,'pdvar:InvalidMultiplication');
end

function test_zero_known_and_decision_rate_tables_rejected_in_both_orders(testCase)
    % Mixed classes must retain the same active-rate boundary before zero shortcuts.
    P = pdvar(2,[0 2 5],'full',Degree=1);
    A = pdmat([0 2 5],{[1 2;3 5],[7 11;13 17],[19 23;29 31]},Degree=1);
    D = rhodiff(P,[0 0]);
    K = rhodiff(A,[0 0]);
    testCase.verifyEqual([D.NumRateRows,K.NumRateRows],[1 1]);
    testCase.verifyError(@() K*D,'pdvar:InvalidMultiplication');
    testCase.verifyError(@() D*K,'pdvar:InvalidMultiplication');
end

function test_cancelled_decision_product_rejects_function_only_evidence(testCase)
    % Zero fast paths must validate unsupported source modes in both orders.
    P = pdvar(1,[0 2 5],Degree=2);
    Z = P-P;
    F = pdmat([0 2 5],@(r) r);
    testCase.verifyError(@() Z*F,'pdvar:FunctionOnlyAlgebra');
    testCase.verifyError(@() F*Z,'pdvar:FunctionOnlyAlgebra');
end

function test_tensor_refined_rectangular_affine_product_chain(testCase)
    % Noncommuting known factors combine two grid refinements and degree growth.
    grid = {[0 2 5],[-3 1 6]};
    P = pdvar(2,3,grid,'full',Degree=[1 0]);
    A = pdmat({[0 1 5],[-3 6]},@(x,y) [1+x y;2-y 3-x],Degree=[1 1]);
    B = pdmat({[0 5],[-3 0 6]},@(x,y) [1 y;2+x -3;4 x-y],Degree=[1 1]);
    R = A*P*B;
    testCase.verifyEqual(R.Degree,[3 2]);
    testCase.verifyEqual(R.MatrixSize,[2 2]);
    testCase.verifyEqual(R.GridInfo.Vectors,{[0 1 2 5],[-3 0 1 6]});
    for x = [0 .4 1.5 3.7 5]
        for y = [-3 -1 .5 3 6]
            left = [1+x y;2-y 3-x];
            right = [1 y;2+x -3;4 x-y];
            tests.infrastructure.verify_expr(testCase,R.evaluate([x y]), ...
                left*P.evaluate([x y])*right);
        end
    end
end

function setupOnce(~)
    yalmip("clear");
end

function test_planned_contractions_exact_affine_bases(testCase)
    % Planned contractions retain exact affine bases and multiplication order.
    grid = {[0 1], [10 20]};
    knownData = cell(3, 3);
    for row = 1:3
        for col = 1:3
            knownData{row, col} = [row, col; row + col, row - col];
        end
    end
    A = pdmat(grid, knownData, Degree=[2 2]);
    P = pdvar(2, grid, "full", Degree=[1 1]);
    knownCoeffs = A.coeffs([1 1]);
    affineCoeffs = P.coeffs([1 1]);

    leftActual = A * P;
    rightActual = P * A;
    leftExpected = legacyBernProduct(knownCoeffs, 2, ...
        affineCoeffs, 1, 2);
    rightExpected = legacyBernProduct(affineCoeffs, 1, ...
        knownCoeffs, 2, 2);

    verifyAffineRow(testCase, leftActual.coeffs([1 1]), leftExpected);
    verifyAffineRow(testCase, rightActual.coeffs([1 1]), rightExpected);
    testCase.verifyEqual(objectVariables(leftActual), objectVariables(P));
    testCase.verifyEqual(objectVariables(rightActual), objectVariables(P));
end

function test_known_coefficient_data_may_multiply_pdvar(testCase)
    % Known coefficient data may multiply a pdvar on either side.
    P = pdvar(1, {[0 1]});
    A = pdmat({[0 1]}, {10, 20}, Degree=1);
    cp = P.coeffs(1);

    L = A * P;
    R = P * A;

    testCase.verifyEqual(L.Degree, 2);
    testCase.verifyEqual(R.Degree, 2);
    exp = {10 * cp{1}, (10 * cp{2} + 20 * cp{1}) / 2, 20 * cp{2}};
    tests.infrastructure.verify_expr(testCase, L.coeffs(1), exp);
    tests.infrastructure.verify_expr(testCase, R.coeffs(1), exp);
end

function test_metadata_only_ratebounds_do_create_active(testCase)
    % Metadata-only RateBounds do not create active derivative-rate rows.
    tauRange = linspace(0, 7, 2);
    tau = pdmat(tauRange, @(x) x, Degree=1);
    Q = pdvar(2, tauRange, RateBounds=[-1 1], Degree=0);
    cq = Q.coeffs(1);

    L = tau * Q;
    R = Q * tau;
    leftScale = 2 * Q;
    rightScale = Q * 2;

    testCase.verifyEqual(size(L), [2 2]);
    testCase.verifyEqual(size(R), [2 2]);
    testCase.verifyEqual(L.Degree, 1);
    testCase.verifyEqual(R.Degree, 1);
    testCase.verifyEqual(L.RateBounds, [-1 1]);
    testCase.verifyEqual(R.RateBounds, [-1 1]);
    testCase.verifyEqual(L.NumRateRows, 0);
    testCase.verifyEqual(R.NumRateRows, 0);
    testCase.verifyEqual(multiplication_objectVariables(L), multiplication_objectVariables(Q));
    testCase.verifyEqual(multiplication_objectVariables(R), multiplication_objectVariables(Q));
    tests.infrastructure.verify_expr(testCase, L.coeffs(1), {zeros(2), 7 * cq{1}});
    tests.infrastructure.verify_expr(testCase, R.coeffs(1), {zeros(2), cq{1} * 7});
    testCase.verifyEqual(leftScale.RateBounds, [-1 1]);
    testCase.verifyEqual(rightScale.RateBounds, [-1 1]);
    testCase.verifyEqual(leftScale.NumRateRows, 0);
    testCase.verifyEqual(rightScale.NumRateRows, 0);
    tests.infrastructure.verify_expr(testCase, leftScale.coeffs(1), {2 * cq{1}});
    tests.infrastructure.verify_expr(testCase, rightScale.coeffs(1), {cq{1} * 2});
end

function test_numeric_products_preserve_affine_yalmip_structure(testCase)
    % Numeric products should preserve affine YALMIP structure.
    P = pdvar(2, 1, {[0 1]}, "full");
    cp = P.coeffs(1);

    S = 3 * P;
    L = [1 2] * P;
    R = P * [4 5];

    testCase.verifyEqual(size(S), [2 1]);
    testCase.verifyEqual(size(L), [1 1]);
    testCase.verifyEqual(size(R), [2 2]);
    tests.infrastructure.verify_expr(testCase, S.coeffs(1), {3 * cp{1}, 3 * cp{2}});
    tests.infrastructure.verify_expr(testCase, L.coeffs(1), {[1 2] * cp{1}, [1 2] * cp{2}});
    tests.infrastructure.verify_expr(testCase, R.coeffs(1), {cp{1} * [4 5], cp{2} * [4 5]});
end

function test_known_multiplication_arbitrary_degree_decisions(testCase)
    % Known multiplication keeps arbitrary-degree decisions affine.
    P = pdvar(1, {[0 1]}, Degree=2);
    A = pdmat({[0 1]}, {2, 5}, Degree=1);
    cp = P.coeffs(1);

    C = P * A;

    testCase.verifyEqual(C.Degree, 3);
    testCase.verifyTrue(C.ContainsDecision);
    tests.infrastructure.verify_expr(testCase, C.coeffs(1), { ...
        2 * cp{1}, ...
        (5 * cp{1} + 4 * cp{2}) / 3, ...
        (10 * cp{2} + 2 * cp{3}) / 3, ...
        5 * cp{3}});
    testCase.verifyError(@() P * pdvar(1, {[0 1]}, Degree=2), ...
        "pdvar:InvalidMultiplication");
end

function test_scalar_pdvar_scale_numeric_pdmat_matrices(testCase)
    % A scalar pdvar should scale numeric and pdmat matrices in either order.
    G = pdvar(1, [0 1], Degree=0);
    cg = G.coeffs(1);
    A = pdmat([0 1], {eye(2), 2 * eye(2)}, Degree=1);

    R = G * eye(2);
    L = eye(2) * G;
    knownRight = G * A;
    knownLeft = A * G;

    testCase.verifyEqual(size(R), [2 2]);
    testCase.verifyEqual(size(L), [2 2]);
    testCase.verifyEqual(R.Degree, 0);
    testCase.verifyEqual(L.Degree, 0);
    tests.infrastructure.verify_expr(testCase, R.coeffs(1), {cg{1} * eye(2)});
    tests.infrastructure.verify_expr(testCase, L.coeffs(1), {eye(2) * cg{1}});
    testCase.verifyEqual(size(knownRight), [2 2]);
    testCase.verifyEqual(size(knownLeft), [2 2]);
    testCase.verifyEqual(knownRight.Degree, 1);
    testCase.verifyEqual(knownLeft.Degree, 1);
    tests.infrastructure.verify_expr(testCase, knownRight.coeffs(1), ...
        {cg{1} * eye(2), cg{1} * 2 * eye(2)});
    tests.infrastructure.verify_expr(testCase, knownLeft.coeffs(1), ...
        {eye(2) * cg{1}, 2 * eye(2) * cg{1}});
end

function test_unequal_direction_wise_degrees_add_while(testCase)
    % Unequal direction-wise degrees add while both operand orders stay affine.
    grid = {[0 1], [10 20]};
    P = pdvar(1, grid, Degree=[1 2]);
    knownData = cell(3, 2);
    for i = 0:2
        for j = 0:1
            knownData{i + 1, j + 1} = 2 + j;
        end
    end
    A = pdmat(grid, knownData, Degree=[2 1]);

    left = A * P;
    right = P * A;

    testCase.verifyEqual(left.Degree, [3 3]);
    testCase.verifyEqual(right.Degree, [3 3]);
    testCase.verifyEqual(multiplication_objectVariables(left), multiplication_objectVariables(P));
    testCase.verifyEqual(multiplication_objectVariables(right), multiplication_objectVariables(P));
    testCase.verifyTrue(is(left.evaluate([0.3 14]), "linear"));
    testCase.verifyTrue(is(right.evaluate([0.3 14]), "linear"));

    coeffs = P.coeffs([1 1]);
    for k = 1:numel(coeffs)
        assign(coeffs{k}, k);
    end
    point = [0.3 14];
    expected = A.evaluate(point) * value(P.evaluate(point));
    testCase.verifyEqual(value(left.evaluate(point)), expected, ...
        AbsTol=1e-10);
    testCase.verifyEqual(value(right.evaluate(point)), expected, ...
        AbsTol=1e-10);
end

function test_scalar_pdmat_scale_matrix_valued_decisions(testCase)
    % A scalar pdmat should scale matrix-valued decisions on either side.
    S = pdmat([0 1], {2, 4}, Degree=1);
    P = pdvar(2, 2, [0 1], "full");
    cp = P.coeffs(1);

    knownLeft = S * P;
    knownRight = P * S;
    expected = {
        2 * cp{1}, ...
        (2 * cp{2} + 4 * cp{1}) / 2, ...
        4 * cp{2}
        };

    testCase.verifyEqual(size(knownLeft), [2 2]);
    testCase.verifyEqual(size(knownRight), [2 2]);
    testCase.verifyEqual(knownLeft.Degree, 2);
    testCase.verifyEqual(knownRight.Degree, 2);
    tests.infrastructure.verify_expr(testCase, knownLeft.coeffs(1), expected);
    tests.infrastructure.verify_expr(testCase, knownRight.coeffs(1), expected);
end

function test_exercise_complete_accepted_scalar_matrix(testCase)
    % Exercise the complete accepted scalar/matrix compatibility table.
    x = sdpvar(1, 1);
    X = sdpvar(2, 2, 'full');
    S = pdmat([0 1], {2, 3, 4}, Degree=2);
    A = pdmat([0 1], {eye(2), 2 * eye(2)}, Degree=1);
    G = pdvar(1, [0 1], Degree=2);
    P = pdvar(2, 2, [0 1], "full", Degree=1);

    scalars = {3, x, S, G};
    matrices = {[1 2; 3 5], A, X, P};
    pairs = [
        1 1; 1 2; 2 1; 2 2; 3 1; 3 2; 4 1; 4 2
        1 3; 1 4; 3 3; 3 4
        ];

    vars = unique([getvariables(x), getvariables(X), ...
        multiplication_objectVariables(G), multiplication_objectVariables(P)]);
    assign(recover(vars), 1:numel(vars));

    for k = 1:size(pairs, 1)
        scalar = scalars{pairs(k, 1)};
        matrix = matrices{pairs(k, 2)};
        left = scalar * matrix;
        right = matrix * scalar;
        multiplication_verifyCompatibilityPair(testCase, scalar, matrix, left, right);
    end
end

function test_package_expressions_still_reject_scalar_matrix(testCase)
    % Package expressions still reject every scalar/matrix double-decision order.
    x = sdpvar(1, 1);
    X = sdpvar(2, 2, 'full');
    G = pdvar(1, [0 1]);
    P = pdvar(2, 2, [0 1], "full");
    ops = {@() x * P, @() P * x, @() G * X, @() X * G, ...
        @() G * P, @() P * G};

    for k = 1:numel(ops)
        testCase.verifyError(ops{k}, "pdvar:InvalidMultiplication");
    end
end

function test_known_data_products_preserve_output_row(testCase)
    % Known-data products should preserve one output row per rate vertex.
    P = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);
    A = pdmat({[0 1]}, {10, 20}, Degree=1);

    L = A * D;
    R = D * A;
    S = 3 * D;
    T = D * 4;

    testCase.verifyEqual(L.Degree, 1);
    testCase.verifyEqual(L.RateBounds, [-1 2]);
    tests.infrastructure.verify_expr(testCase, L.coeffs(1), {
        10 * cd{1, 1}, 20 * cd{1, 1}
        10 * cd{2, 1}, 20 * cd{2, 1}
    });
    tests.infrastructure.verify_expr(testCase, R.coeffs(1), {
        cd{1, 1} * 10, cd{1, 1} * 20
        cd{2, 1} * 10, cd{2, 1} * 20
    });
    tests.infrastructure.verify_expr(testCase, S.coeffs(1), {3 * cd{1, 1}; 3 * cd{2, 1}});
    tests.infrastructure.verify_expr(testCase, T.coeffs(1), {cd{1, 1} * 4; cd{2, 1} * 4});
end

function test_known_rate_row_factor_affine_safe(testCase)
    % One known rate-row factor is affine-safe on either side of pdvar.
    rb = [-1 2];
    P = pdvar(1, [0 1]);
    cp = P.coeffs(1);
    R = pdmat([0 1], {{1, 3; 10, 14}}, ...
        Degree=1, RateBounds=rb);

    L = R * P;
    U = P * R;
    expected = {
        cp{1}, (3 * cp{1} + cp{2}) / 2, 3 * cp{2}
        10 * cp{1}, (14 * cp{1} + 10 * cp{2}) / 2, 14 * cp{2}
        };

    testCase.verifyClass(L, "pdvar");
    testCase.verifyClass(U, "pdvar");
    testCase.verifyEqual(L.RateBounds, rb);
    testCase.verifyEqual(U.RateBounds, rb);
    tests.infrastructure.verify_expr(testCase, L.coeffs(1), expected);
    tests.infrastructure.verify_expr(testCase, U.coeffs(1), expected);
end

function test_numeric_matrices_may_multiply_rate_row(testCase)
    % Numeric matrices may multiply a rate-row vector on either side.
    V = pdvar(2, 1, {[0 1]}, "full");
    D = rhodiff(V, [-1 1]);
    cd = D.coeffs(1);

    L = [1 2] * D;
    R = D * [4 5];

    testCase.verifyEqual(size(L), [1 1]);
    testCase.verifyEqual(size(R), [2 2]);
    tests.infrastructure.verify_expr(testCase, L.coeffs(1), {[1 2] * cd{1, 1}; [1 2] * cd{2, 1}});
    tests.infrastructure.verify_expr(testCase, R.coeffs(1), {cd{1, 1} * [4 5]; cd{2, 1} * [4 5]});
end

function test_scalar_matrix_placement_preserve_derivative_row(testCase)
    % Every scalar/matrix placement should preserve one derivative row table.
    rb = [-1 2];
    scalarData = pdmat([0 1], {1, 3}, Degree=1, RateBounds=rb);
    matrixData = pdmat([0 1], {eye(2), 2 * eye(2)}, ...
        Degree=1, RateBounds=rb);
    ordinaryScalarData = pdmat([0 1], {2, 4}, Degree=1);
    ordinaryMatrixData = pdmat([0 1], ...
        {eye(2), 2 * eye(2)}, Degree=1);
    scalarDecision = pdvar(1, [0 1]);
    matrixDecision = pdvar(2, 2, [0 1], "full");
    derivativeScalarData = rhodiff(scalarData);
    derivativeMatrixData = rhodiff(matrixData);
    derivativeScalarDecision = rhodiff(scalarDecision, rb);
    derivativeMatrixDecision = rhodiff(matrixDecision, rb);
    cs = scalarDecision.coeffs(1);
    cm = matrixDecision.coeffs(1);
    cds = derivativeScalarDecision.coeffs(1);
    cdm = derivativeMatrixDecision.coeffs(1);

    expectedDataScalar = {
        -2 * cm{1}, -2 * cm{2}
        4 * cm{1}, 4 * cm{2}
        };
    expectedDecisionMatrix = {
        2 * cdm{1, 1}, 4 * cdm{1, 1}
        2 * cdm{2, 1}, 4 * cdm{2, 1}
        };
    expectedDecisionScalar = {
        cds{1, 1} * eye(2), cds{1, 1} * 2 * eye(2)
        cds{2, 1} * eye(2), cds{2, 1} * 2 * eye(2)
        };
    expectedDataMatrix = {
        cs{1} * -eye(2), cs{2} * -eye(2)
        cs{1} * 2 * eye(2), cs{2} * 2 * eye(2)
        };

    verifyRateProduct(testCase, derivativeScalarData * matrixDecision, ...
        expectedDataScalar);
    verifyRateProduct(testCase, matrixDecision * derivativeScalarData, ...
        expectedDataScalar);
    verifyRateProduct(testCase, ordinaryScalarData * derivativeMatrixDecision, ...
        expectedDecisionMatrix);
    verifyRateProduct(testCase, derivativeMatrixDecision * ordinaryScalarData, ...
        expectedDecisionMatrix);
    verifyRateProduct(testCase, derivativeScalarDecision * ordinaryMatrixData, ...
        expectedDecisionScalar);
    verifyRateProduct(testCase, ordinaryMatrixData * derivativeScalarDecision, ...
        expectedDecisionScalar);
    verifyRateProduct(testCase, scalarDecision * derivativeMatrixData, ...
        expectedDataMatrix);
    verifyRateProduct(testCase, derivativeMatrixData * scalarDecision, ...
        expectedDataMatrix);

    testCase.verifyError( ...
        @() derivativeScalarData * derivativeMatrixDecision, ...
        "pdvar:InvalidMultiplication");
    testCase.verifyError( ...
        @() derivativeMatrixDecision * derivativeScalarData, ...
        "pdvar:InvalidMultiplication");
    testCase.verifyError( ...
        @() derivativeScalarDecision * derivativeMatrixData, ...
        "pdvar:InvalidMultiplication");
    testCase.verifyError( ...
        @() derivativeMatrixData * derivativeScalarDecision, ...
        "pdvar:InvalidMultiplication");
end

function test_zero_products_carry_decision_rate_metadata(testCase)
    % Zero products should not carry decision/rate metadata or form BMIs.
    P = pdvar(2, 1, {[0 1]}, "full");
    D = rhodiff(P, [-1 1]);
    V = pdvar(1, 2, {[0 1]}, "full");
    W = pdvar(2, 1, {[0 1]}, "full");
    Z = V - V;

    Z1 = P * 0;
    Z2 = 0 * P;
    Z3 = D * 0;
    Z4 = zeros(1, 2) * P;
    Z5 = P * zeros(1, 3);
    Z6 = Z * W;
    Z7 = Z * 2;
    Z8 = 2 * Z;

    verifyZeroPdvar(testCase, Z1, [2 1]);
    verifyZeroPdvar(testCase, Z2, [2 1]);
    verifyZeroPdvar(testCase, Z3, [2 1]);
    verifyZeroPdvar(testCase, Z4, [1 1]);
    verifyZeroPdvar(testCase, Z5, [2 3]);
    verifyZeroPdvar(testCase, Z6, [1 1]);
    verifyZeroPdvar(testCase, Z7, [1 2]);
    verifyZeroPdvar(testCase, Z8, [1 2]);
    testCase.verifyError(@() P * zeros(2, 1), "pdvar:InvalidMultiplication");
    testCase.verifyError(@() Z * NaN, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() complex(0, 1) * Z, "pdvar:InvalidMultiplication");
end

function test_zero_derivative_products_validate_both_rate(testCase)
    % Zero derivative products validate both rate-aware operand orders.
    P = pdvar(1, {[0 1]}, Degree=1);
    D = rhodiff(P, [-1 1]);
    Z = D - D;
    A = pdmat([0 1], {2, 3}, Degree=1);

    left = Z * A;
    right = A * Z;

    verifyZeroPdvar(testCase, left, [1 1]);
    verifyZeroPdvar(testCase, right, [1 1]);
end

function test_products_same_bound_mixed_grids_recomputed(testCase)
    % Products on same-bound mixed grids are recomputed cell-wisely.
    P = pdvar(1, {[0 1]});
    A = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    cp = P.coeffs(1);

    C = P * A;

    testCase.verifyEqual(C.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(C.Degree, 2);
    pMid = 0.5 * cp{1} + 0.5 * cp{2};
    tests.infrastructure.verify_expr(testCase, C.coeffs(1), { ...
        cp{1} * 10, ...
        (cp{1} * 20 + pMid * 10) / 2, ...
        pMid * 20});
    tests.infrastructure.verify_expr(testCase, C.coeffs(2), { ...
        pMid * 20, ...
        (pMid * 30 + cp{2} * 20) / 2, ...
        cp{2} * 30});
end

function test_chained_affine_products_preserve_degree_growth(testCase)
    % Chained affine products should preserve degree growth and coefficients.
    P = pdvar(1, {[0 1]});
    A = pdmat({[0 1]}, {10, 20}, Degree=1);
    B = pdmat({[0 1]}, {1, 2, 3}, Degree=2);
    C = pdmat({[0 1]}, {4, 5}, Degree=1);
    D = pdmat({[0 1]}, {7, 8, 9, 10}, Degree=3);
    cp = P.coeffs(1);

    E = (P * A + B) * C - D;

    s0 = 10 * cp{1} + 1;
    s1 = (20 * cp{1} + 10 * cp{2}) / 2 + 2;
    s2 = 20 * cp{2} + 3;
    testCase.verifyEqual(E.Degree, 3);
    tests.infrastructure.verify_expr(testCase, E.coeffs(1), { ...
        s0 * 4 - 7, ...
        s0 * 5 / 3 + s1 * 8 / 3 - 8, ...
        s1 * 10 / 3 + s2 * 4 / 3 - 9, ...
        s2 * 5 - 10});
end

function test_products_that_leave_affine_sdp_layer(testCase)
    % Products that leave the affine SDP layer should fail clearly.
    P = pdvar(1, {[0 1]});
    Q = pdvar(1, {[0 1]});
    V = pdvar(2, 1, {[0 1]}, "full");
    A = pdmat({[0 2]}, {1, 2}, Degree=1);
    B = pdmat({[0 1]}, {ones(2), 2 * ones(2)}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho);
    x = sdpvar(1, 1);
    X = pdvar(2, 2, {[0 1]}, "full");

    testCase.verifyError(@() P * Q, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() P * X, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() X * P, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() P * x, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() P * F, "pdvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() F * P, "pdvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() P * A, "pdvar:MixedGrid");
    testCase.verifyError(@() V * B, "pdvar:InvalidMultiplication");
end

function test_rate_row_products_require_matching_grid(testCase)
    % Rate-row products require a matching-grid known-data partner.
    P = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 1]);
    Q = pdvar(1, {[0 1]});
    A = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    B = pdmat({[0 2]}, {10, 20}, Degree=1);

    testCase.verifyError(@() D * D, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() D * Q, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() Q * D, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() D * A, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() A * D, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() D * B, "pdvar:MixedGrid");
end

function out = legacyBernProduct(lhs, lhsDegree, rhs, rhsDegree, nParameters)
    % Direct pair-sum oracle independent of product-plan implementation.
    lhsDegree = expandDegree(lhsDegree, nParameters);
    rhsDegree = expandDegree(rhsDegree, nParameters);
    outputDegree = lhsDegree + rhsDegree;
    lhsLabels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, lhsDegree, ...
        "UniformOutput", false));
    outputLabels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, ...
        outputDegree, "UniformOutput", false));
    out = cell(1, size(outputLabels, 1));
    for outputIndex = 1:size(outputLabels, 1)
        outputLabel = outputLabels(outputIndex, :);
        accumulator = [];
        for lhsIndex = 1:size(lhsLabels, 1)
            lhsLabel = lhsLabels(lhsIndex, :);
            rhsLabel = outputLabel - lhsLabel;
            if any(rhsLabel < 0) || any(rhsLabel > rhsDegree)
                continue
            end
            rhsIndex = labelIndex(rhsLabel, rhsDegree);
            scale = productScale(lhsLabel, lhsDegree, ...
                rhsLabel, rhsDegree, outputLabel);
            term = (lhs{lhsIndex} * rhs{rhsIndex}) .* scale;
            if isempty(accumulator)
                accumulator = term;
            else
                accumulator = accumulator + term;
            end
        end
        out{outputIndex} = accumulator;
    end
end

function verifyAffineRow(testCase, actual, expected)
    % Compare YALMIP variable identities and complete affine base matrices.
    testCase.verifyEqual(size(actual), size(expected));
    for coefficient = 1:numel(actual)
        testCase.verifyEqual(getvariables(actual{coefficient}), ...
            getvariables(expected{coefficient}));
        difference = actual{coefficient} - expected{coefficient};
        base = full(getbase(difference));
        testCase.verifyLessThanOrEqual(norm(base, "fro"), ...
            128 * eps(max(1, norm(full(getbase(expected{coefficient})), "fro"))));
    end
end

function variables = objectVariables(obj)
    % Collect unique decision identifiers across cells, rows, and coefficients.
    variables = [];
    cells = obj.cells();
    for cellIndex = 1:size(cells, 1)
        coeffs = obj.coeffs(cells(cellIndex, :));
        for coefficient = 1:numel(coeffs)
            if isa(coeffs{coefficient}, "sdpvar")
                variables = [variables, ...
                    getvariables(coeffs{coefficient})]; %#ok<AGROW>
            end
        end
    end
    variables = unique(variables);
end
function verifyRateProduct(testCase, obj, expected)
    % Check one mixed scalar/matrix product and all of its derivative rows.
    testCase.verifyClass(obj, "pdvar");
    testCase.verifyEqual(size(obj), [2 2]);
    testCase.verifyEqual(obj.Degree, 1);
    testCase.verifyEqual(obj.RateBounds, [-1 2]);
    testCase.verifyEqual(size(obj.coeffs(1)), [2 2]);
    tests.infrastructure.verify_expr(testCase, obj.coeffs(1), expected);
end

function verifyZeroPdvar(testCase, obj, sz)
    % Zero product shortcuts should return compact ordinary coefficients.
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.Degree, zeros(1, obj.npar()));
    testCase.verifyFalse(obj.ContainsDecision);
    testCase.verifyEmpty(obj.RateBounds);
    coeffs = obj.coeffs(ones(1, obj.npar()));
    testCase.verifyEqual(numel(coeffs), 1);
    testCase.verifyEqual(coeffs{1}, zeros(sz));
end

function vars = multiplication_objectVariables(obj)
    % Collect unique symbolic identifiers across the complete coefficient tree.
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
function multiplication_verifyCompatibilityPair(testCase, scalar, matrix, left, right)
    % Check class, metadata, identities, and values for both operand orders.
    expectedClass = productClass(scalar, matrix);
    expectedDegree = operandDegree(scalar) + operandDegree(matrix);
    expectedVars = unique([multiplication_operandVariables(scalar), multiplication_operandVariables(matrix)]);

    testCase.verifyClass(left, expectedClass);
    testCase.verifyClass(right, expectedClass);
    testCase.verifyEqual(size(left), [2 2]);
    testCase.verifyEqual(size(right), [2 2]);
    if isa(left, "pdbase")
        testCase.verifyEqual(left.Degree, expectedDegree);
        testCase.verifyEqual(right.Degree, expectedDegree);
        testCase.verifyEqual(left.GridInfo.Vectors{1}, [0 1]);
        testCase.verifyEqual(right.GridInfo.Vectors{1}, [0 1]);
    end
    if isa(left, "pdvar")
        testCase.verifyEqual(multiplication_objectVariables(left), expectedVars);
        testCase.verifyEqual(multiplication_objectVariables(right), expectedVars);
    end

    for rho = [0 0.25 0.7 1]
        scalarValue = operandValue(scalar, rho);
        matrixValue = operandValue(matrix, rho);
        testCase.verifyEqual(operandValue(left, rho), ...
            scalarValue * matrixValue, AbsTol=1e-10);
        testCase.verifyEqual(operandValue(right, rho), ...
            matrixValue * scalarValue, AbsTol=1e-10);
    end
end

function scale = productScale(lhsLabel, lhsDegree, rhsLabel, ...
        rhsDegree, outputLabel)
    % Return the tensor Bernstein product normalization.
    outputDegree = lhsDegree + rhsDegree;
    scale = 1;
    for parameter = 1:numel(outputLabel)
        scale = scale ...
            * nchoosek(lhsDegree(parameter), lhsLabel(parameter)) ...
            * nchoosek(rhsDegree(parameter), rhsLabel(parameter)) ...
            / nchoosek(outputDegree(parameter), outputLabel(parameter));
    end
end

function index = labelIndex(label, degree)
    % Convert repository mixed-radix label order to a one-based index.
    multipliers = fliplr(cumprod([1, fliplr(degree(2:end) + 1)]));
    index = label * multipliers' + 1;
end

function degree = expandDegree(degree, nParameters)
    % Expand scalar shorthand without sharing production normalizer logic.
    degree = reshape(degree, 1, []);
    if isscalar(degree)
        degree = repmat(degree, 1, nParameters);
    end
end

function name = productClass(lhs, rhs)
    % Return the class required by the accepted scalar compatibility table.
    if isa(lhs, "pdvar") || isa(rhs, "pdvar") || ...
            ((isa(lhs, "sdpvar") || isa(rhs, "sdpvar")) && ...
            (isa(lhs, "pdmat") || isa(rhs, "pdmat")))
        name = "pdvar";
    elseif isa(lhs, "pdmat") || isa(rhs, "pdmat")
        name = "pdmat";
    elseif isa(lhs, "sdpvar") || isa(rhs, "sdpvar")
        name = "sdpvar";
    else
        name = "double";
    end
end

function deg = operandDegree(obj)
    % Numeric and bare sdpvar operands are parameter-independent Degree zero.
    if isa(obj, "pdbase")
        deg = obj.Degree;
    else
        deg = 0;
    end
end

function val = operandValue(obj, rho)
    % Evaluate package and native operands through one test-only oracle.
    if isa(obj, "pdbase")
        val = value(obj.evaluate(rho));
    elseif isa(obj, "sdpvar")
        val = value(obj);
    else
        val = obj;
    end
end

function vars = multiplication_operandVariables(obj)
    % Collect decision identifiers without counting known pdmat coefficients.
    if isa(obj, "pdvar")
        vars = multiplication_objectVariables(obj);
    elseif isa(obj, "sdpvar")
        vars = getvariables(obj);
    else
        vars = [];
    end
end

function test_noncommuting_matrix_products_all_rows(testCase)
    A = tests.infrastructure.fixture("pdvar", true);
    B = pdmat([0 2 5], {[2 3;-5 7],[11 -13;17 19],[23 29;31 -37]}, Degree=1);
    left = A*B;
    right = B*A;
    for cellIndex = 1:2
        a = A.coeffs(cellIndex);
        b = B.coeffs(cellIndex);
        expectedL = cell(2,3); expectedR = cell(2,3);
        for row = 1:2
            expectedL(row,:) = {a{row,1}*b{1}, (a{row,1}*b{2}+a{row,2}*b{1})/2, a{row,2}*b{2}};
            expectedR(row,:) = {b{1}*a{row,1}, (b{1}*a{row,2}+b{2}*a{row,1})/2, b{2}*a{row,2}};
        end
        tests.infrastructure.verify_expr(testCase,left.coeffs(cellIndex),expectedL);
        tests.infrastructure.verify_expr(testCase,right.coeffs(cellIndex),expectedR);
    end
    testCase.verifyEqual(left.Degree,2);
    testCase.verifyEqual(right.NumRateRows,2);
end
