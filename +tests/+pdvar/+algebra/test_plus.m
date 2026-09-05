function tests = test_plus
    % Behavioral regressions for pdvar.plus.
    tests = functiontests(localfunctions);
end

function test_tensor_refinement_preserves_full_affine_bases(testCase)
    % Distinct decisions and zero-degree axes cannot be merged by assigned values.
    P = pdvar(2,3,{[0 1 3],[-2 4]},'full',Degree=[1 0]);
    Q = pdvar(2,3,{[0 3],[-2 0 4]},'full',Degree=[0 2]);
    R = P+Q;
    testCase.verifyEqual(R.GridInfo.Vectors,{[0 1 3],[-2 0 4]});
    testCase.verifyEqual(R.Degree,[1 2]);
    for x = [0 .4 1 2.3 3]
        for y = [-2 -1 0 1.7 4]
            tests.infrastructure.verify_expr(testCase,R.evaluate([x y]), ...
                P.evaluate([x y])+Q.evaluate([x y]));
        end
    end
end

function test_cancelled_decision_still_rejects_function_only_partner(testCase)
    % Zero algebra cannot bypass the known-data evidence boundary.
    P = pdvar(1,[0 2 5],Degree=2);
    Z = P-P;
    F = pdmat([0 2 5],@(r) r);
    testCase.verifyError(@() Z+F,'pdvar:FunctionOnlyAlgebra');
    testCase.verifyError(@() F+Z,'pdvar:FunctionOnlyAlgebra');
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function test_numeric_constants_become_degree_0_data(testCase)
    % Numeric constants become degree-0 data and are elevated to degree 1.
    P = pdvar(2, {[0 1]}, "full");
    cp = P.coeffs(1);
    S = P + 5;
    D = eye(2) - P;

    tests.infrastructure.verify_expr(testCase, S.coeffs(1), {cp{1} + 5 * ones(2), cp{2} + 5 * ones(2)});
    tests.infrastructure.verify_expr(testCase, D.coeffs(1), {eye(2) - cp{1}, eye(2) - cp{2}});
end

function test_zero_pdvar_pdmat_numeric_operands_preserve(testCase)
    % Zero pdvar/pdmat/numeric operands preserve identity without skipping checks.
    P = pdvar(1, {[0 1]});
    Z = P - P;
    knownZero = pdmat({[0 1]}, {0}, Degree=0);

    testCase.verifyTrue(isequal(Z + P, P));
    testCase.verifyTrue(isequal(P + Z, P));
    testCase.verifyTrue(isequal(P + knownZero, P));
    testCase.verifyTrue(isequal(knownZero + P, P));
    testCase.verifyTrue(isequal(P + 0, P));
    testCase.verifyTrue(isequal(zeros(1) + P, P));

    matrixZero = pdmat({[0 1]}, {zeros(2)}, Degree=0);
    testCase.verifyError(@() P + matrixZero, "pdvar:InvalidAddition");

    otherGridZero = pdmat({[0 2]}, {0}, Degree=0);
    testCase.verifyError(@() P + otherGridZero, "pdvar:MixedGrid");

    matrixZeroForMinus = pdmat({[0 1]}, {zeros(2)}, Degree=0);
    testCase.verifyError(@() P - matrixZeroForMinus, ...
        "pdvar:InvalidSubtraction");
end

function test_bare_affine_sdpvar_matrices_promote_constant(testCase)
    % Bare affine sdpvar matrices promote to constant coefficient data.
    P = pdvar(2, {[0 1]}, "full");
    X = sdpvar(2, 2, 'full');
    cp = P.coeffs(1);
    C = P + X;

    tests.infrastructure.verify_expr(testCase, C.coeffs(1), {cp{1} + X, cp{2} + X});
end

function test_coefficient_backed_pdmat_operands_can_enter(testCase)
    % Coefficient-backed pdmat operands can enter affine pdvar expressions.
    P = pdvar(1, {[0 1]});
    A = pdmat({[0 1]}, {10, 20}, Degree=1);
    cp = P.coeffs(1);

    C = P + A;

    testCase.verifyEqual(C.Degree, 1);
    tests.infrastructure.verify_expr(testCase, C.coeffs(1), {cp{1} + 10, cp{2} + 20});
end

function test_restrict_coarse_quadratic_at_alpha_5(testCase)
    % Restrict a coarse quadratic at alpha=5/12 onto two unequal cells.
    P = pdvar(1, {[-2 4]}, Degree=2);
    Q = pdvar(1, {[-2 0.5 4]}, Degree=2);
    cp = P.coeffs(1);
    cq1 = Q.coeffs(1);
    cq2 = Q.coeffs(2);

    S = P + Q;

    shared = (49 * cp{1} + 70 * cp{2} + 25 * cp{3}) / 144;
    testCase.verifyEqual(S.GridInfo.Vectors{1}, [-2 0.5 4]);
    testCase.verifyEqual(S.Degree, 2);
    tests.infrastructure.verify_expr(testCase, S.coeffs(1), { ...
        cp{1} + cq1{1}, ...
        (7 * cp{1} + 5 * cp{2}) / 12 + cq1{2}, ...
        shared + cq1{3}});
    tests.infrastructure.verify_expr(testCase, S.coeffs(2), { ...
        shared + cq2{1}, ...
        (7 * cp{2} + 5 * cp{3}) / 12 + cq2{2}, ...
        cp{3} + cq2{3}});
end

function test_complete_residual_in_both_orders(testCase)
    A = tests.infrastructure.fixture("pdvar", true);
    saved = A.LocalValues;
    constant = [2 -7;11 3];
    left = A + constant;
    right = constant + A;
    for cellIndex = 1:2
        c = A.coeffs(cellIndex);
        tests.infrastructure.verify_expr(testCase,left.coeffs(cellIndex), ...
            cellfun(@(x) x + constant,c,'UniformOutput',false));
        tests.infrastructure.verify_expr(testCase,right.coeffs(cellIndex), ...
            cellfun(@(x) constant + x,c,'UniformOutput',false));
    end
    testCase.verifyEqual(A.LocalValues,saved);
    testCase.verifyError(@() A + ones(3), 'pdvar:InvalidAddition');
end
