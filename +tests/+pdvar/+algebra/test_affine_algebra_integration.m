function tests = test_affine_algebra_integration
    % Behavioral regressions for pdvar.affine_algebra_integration.
    tests = functiontests(localfunctions);
end

function test_tensor_derivative_slice_known_sandwich_and_reduction(testCase)
    % A composed affine path must preserve all active vertices and decision bases.
    P = pdvar(2,3,{[0 2 5],[-3 1 6]},'full',Degree=[1 2]);
    D = rhodiff(P,[3 3;-2 5]);
    L = [2 -3;5 7]; R = [1 -2;3 5;-7 11];
    A = L*D*R;
    B = sum(transpose(A),2);
    for subs = [1 1;1 2;2 1;2 2]'
        c = D.coeffs(subs');
        expected = cellfun(@(x) sum(transpose(L*x*R),2),c,'UniformOutput',false);
        tests.infrastructure.verify_expr(testCase,B.coeffs(subs'),expected);
    end
    testCase.verifyEqual(B.NumRateRows,2);
    testCase.verifyEqual(B.RateBounds,[3 3;-2 5]);
    testCase.verifyError(@() B*P,'pdvar:InvalidMultiplication');
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function test_binary_unary_operations_act_coefficient_wise(testCase)
    % Binary and unary operations should act coefficient-wise.
    P = pdvar(1, {[0 1]});
    Q = pdvar(1, {[0 1]});

    cp = P.coeffs(1);
    cq = Q.coeffs(1);
    S = P + Q;
    D = P - Q;
    N = -P;
    U = +P;

    tests.infrastructure.verify_expr(testCase, S.coeffs(1), {cp{1} + cq{1}, cp{2} + cq{2}});
    tests.infrastructure.verify_expr(testCase, D.coeffs(1), {cp{1} - cq{1}, cp{2} - cq{2}});
    tests.infrastructure.verify_expr(testCase, N.coeffs(1), {-cp{1}, -cp{2}});
    tests.infrastructure.verify_expr(testCase, U.coeffs(1), cp);
end

function test_known_zero_rate_table_cannot_take(testCase)
    % A known zero rate table cannot take the metadata-free identity shortcut.
    rb = [-1 2];
    P = pdvar(1, [0 1]);
    cp = P.coeffs(1);
    Z = pdmat([0 1], {{0, 0; 0, 0}}, Degree=1, RateBounds=rb);

    S = P + Z;

    testCase.verifyEqual(S.RateBounds, rb);
    tests.infrastructure.verify_expr(testCase, S.coeffs(1), {
        cp{1}, cp{2}
        cp{1}, cp{2}
        });
end

function test_arbitrary_degree_constructor_values_participate(testCase)
    % Arbitrary-degree constructor values participate in exact elevation.
    P = pdvar(1, {[0 1]}, Degree=2);
    Q = pdvar(1, {[0 1]}, Degree=3);
    cp = P.coeffs(1);
    cq = Q.coeffs(1);

    S = P + 5;
    D = P - Q;

    testCase.verifyEqual(S.Degree, 2);
    tests.infrastructure.verify_expr(testCase, S.coeffs(1), ...
        {cp{1} + 5, cp{2} + 5, cp{3} + 5});
    testCase.verifyEqual(D.Degree, 3);
    tests.infrastructure.verify_expr(testCase, D.coeffs(1), { ...
        cp{1} - cq{1}, ...
        (cp{1} + 2 * cp{2}) / 3 - cq{2}, ...
        (2 * cp{2} + cp{3}) / 3 - cq{3}, ...
        cp{3} - cq{4}});
end

function test_rate_rows_work_either_side_supported(testCase)
    % Rate rows should work on either side of supported affine operands.
    P = pdvar(1, {[0 1]});
    Q = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);
    cq = Q.coeffs(1);
    X = sdpvar(1, 1);
    A = pdmat({[0 1]}, {10, 20}, Degree=1);

    L = D + Q;
    R = Q + D;
    N = 5 - D;
    S = D + 5;
    Y = X - D;
    K = A - D;

    testCase.verifyEqual(L.Degree, 1);
    testCase.verifyEqual(L.RateBounds, [-1 2]);
    tests.infrastructure.verify_expr(testCase, L.coeffs(1), {
        cd{1, 1} + cq{1}, cd{1, 1} + cq{2}
        cd{2, 1} + cq{1}, cd{2, 1} + cq{2}
    });
    tests.infrastructure.verify_expr(testCase, R.coeffs(1), {
        cq{1} + cd{1, 1}, cq{2} + cd{1, 1}
        cq{1} + cd{2, 1}, cq{2} + cd{2, 1}
    });
    tests.infrastructure.verify_expr(testCase, N.coeffs(1), {5 - cd{1, 1}; 5 - cd{2, 1}});
    tests.infrastructure.verify_expr(testCase, S.coeffs(1), {cd{1, 1} + 5; cd{2, 1} + 5});
    tests.infrastructure.verify_expr(testCase, Y.coeffs(1), {X - cd{1, 1}; X - cd{2, 1}});
    tests.infrastructure.verify_expr(testCase, K.coeffs(1), {
        10 - cd{1, 1}, 20 - cd{1, 1}
        10 - cd{2, 1}, 20 - cd{2, 1}
    });
end

function test_same_bound_mixed_scalar_grids_align(testCase)
    % Same-bound mixed scalar grids should align on a common refinement.
    P = pdvar(1, {[0 1]});
    Q = pdvar(1, {[0 0.5 1]});
    cp = P.coeffs(1);
    cq1 = Q.coeffs(1);
    cq2 = Q.coeffs(2);

    S = P + Q;

    testCase.verifyEqual(S.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(S.Degree, 1);
    tests.infrastructure.verify_expr(testCase, S.coeffs(1), { ...
        cp{1} + cq1{1}, ...
        0.5 * cp{1} + 0.5 * cp{2} + cq1{2}});
    tests.infrastructure.verify_expr(testCase, S.coeffs(2), { ...
        0.5 * cp{1} + 0.5 * cp{2} + cq2{1}, ...
        cp{2} + cq2{2}});
end

function test_affine_sums_align_unequal_degrees_by(testCase)
    % Affine sums align unequal degrees by componentwise maximum.
    grid = {[0 1], [10 20]};
    P = pdvar(1, grid, Degree=[1 3]);
    Q = pdvar(1, grid, Degree=[2 1]);
    pe = P.elevate([1 0]);
    qe = Q.elevate([0 2]);

    S = P + Q;
    R = P - Q;
    testCase.verifyEqual(S.Degree, [2 3]);
    testCase.verifyEqual(R.Degree, [2 3]);
    tests.infrastructure.verify_expr(testCase, S.coeffs([1 1]), ...
        cellfun(@plus, pe.coeffs([1 1]), qe.coeffs([1 1]), ...
        UniformOutput=false));
    tests.infrastructure.verify_expr(testCase, R.coeffs([1 1]), ...
        cellfun(@minus, pe.coeffs([1 1]), qe.coeffs([1 1]), ...
        UniformOutput=false));

    Z = pdvar(1, grid, Degree=[0 2]);
    plusRight = Z + 2;
    minusLeft = 2 - Z;
    testCase.verifyEqual(plusRight.Degree, [0 2]);
    testCase.verifyEqual(minusLeft.Degree, [0 2]);
    tests.infrastructure.verify_expr(testCase, plusRight.coeffs([1 1]), ...
        cellfun(@(x) x + 2, Z.coeffs([1 1]), UniformOutput=false));
    tests.infrastructure.verify_expr(testCase, minusLeft.coeffs([1 1]), ...
        cellfun(@(x) 2 - x, Z.coeffs([1 1]), UniformOutput=false));
end

function test_known_rate_row_table_broadcast_ordinary(testCase)
    % A known rate-row table should broadcast an ordinary decision on either side.
    rb = [-1 2];
    P = pdvar(1, [0 1], RateBounds=rb);
    cp = P.coeffs(1);
    R = pdmat([0 1], {{1, 3; 10, 14}}, ...
        Degree=1, RateBounds=rb);

    S = P + R;
    D = R - P;

    testCase.verifyClass(S, "pdvar");
    testCase.verifyClass(D, "pdvar");
    testCase.verifyEqual(S.RateBounds, rb);
    testCase.verifyEqual(size(S.coeffs(1)), [2 2]);
    tests.infrastructure.verify_expr(testCase, S.coeffs(1), {
        cp{1} + 1, cp{2} + 3
        cp{1} + 10, cp{2} + 14
        });
    tests.infrastructure.verify_expr(testCase, D.coeffs(1), {
        1 - cp{1}, 3 - cp{2}
        10 - cp{1}, 14 - cp{2}
        });

    mismatch = pdmat([0 1], {{1, 2; 3, 4}}, ...
        Degree=1, RateBounds=[0 2]);
    testCase.verifyError(@() P + mismatch, "pdvar:InvalidAddition");
end

function test_slice_rejects_mixed_bounds_bad_sizes(testCase)
    % This slice rejects mixed bounds, bad sizes, function-only pdmat, and nonlinear sdpvar inputs.
    P = pdvar(1, {[0 1]});
    Q = pdvar(1, {[0 2]});
    R = pdvar(2, {[0 1]});
    F = pdmat({[0 1]}, @(rho) rho);
    x = sdpvar(1, 1);

    testCase.verifyError(@() P + Q, "pdvar:MixedGrid");
    testCase.verifyError(@() P + R, "pdvar:InvalidAddition");
    testCase.verifyError(@() P + F, "pdvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() P + x * x, "pdvar:InvalidAddition");
end

function test_rate_row_expressions_cannot_resampled_or(testCase)
    % Rate-row expressions cannot be resampled or mixed with bad operands.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    D = rhodiff(P);
    Q = pdvar(2, {[0 1]}, RateBounds=[-1 1]);
    R = pdvar(1, {[0 1]}, RateBounds=[0 1]);
    A = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho);
    x = sdpvar(1, 1);

    testCase.verifyError(@() D + Q, "pdvar:InvalidAddition");
    testCase.verifyError(@() D + R, "pdvar:InvalidAddition");
    testCase.verifyError(@() D + A, "pdvar:InvalidAddition");
    testCase.verifyError(@() D + F, "pdvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() D + x * x, "pdvar:InvalidAddition");
end

function test_missing_ratebounds_inherit_operation_level_metadata(testCase)
    % Missing RateBounds should inherit the operation-level metadata.
    rb = [-1 1];
    P = pdvar(1, {[0 1]}, RateBounds=rb);
    Q = pdvar(1, {[0 1]});
    R = pdvar(1, {[0 1]}, RateBounds=[0 1]);
    cp = P.coeffs(1);
    cq = Q.coeffs(1);

    S = P + Q;
    D = Q - P;

    testCase.verifyEqual(S.RateBounds, rb);
    testCase.verifyEqual(D.RateBounds, rb);
    tests.infrastructure.verify_expr(testCase, S.coeffs(1), {cp{1} + cq{1}, cp{2} + cq{2}});
    tests.infrastructure.verify_expr(testCase, D.coeffs(1), {cq{1} - cp{1}, cq{2} - cp{2}});
    testCase.verifyError(@() P + R, "pdvar:InvalidAddition");
end

function test_cancelled_affine_expressions_become_compact(testCase)
    % Cancelled affine expressions should become compact nondecision zeros.
    P = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 1]);

    Z1 = P - P;
    Z2 = P + (-P);
    Z3 = D - D;

    verifyZeroPdvar(testCase, Z1, [1 1]);
    verifyZeroPdvar(testCase, Z2, [1 1]);
    verifyZeroPdvar(testCase, Z3, [1 1]);
    testCase.verifyTrue(isequal(Z1 + P, P));
    testCase.verifyTrue(isequal(P - Z1, P));
end

function verifyZeroPdvar(testCase, obj, sz)
    % Arithmetic fast paths should remove stale YALMIP/rate metadata.
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.Degree, 0);
    testCase.verifyFalse(obj.ContainsDecision);
    testCase.verifyEmpty(obj.RateBounds);
    coeffs = obj.coeffs(ones(1, obj.npar()));
    testCase.verifyEqual(numel(coeffs), 1);
    testCase.verifyEqual(coeffs{1}, zeros(sz));
end
