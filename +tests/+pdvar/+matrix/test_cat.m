function tests = test_cat
    % Behavioral regressions for pdvar.cat.
    tests = functiontests(localfunctions);
end

function test_tensor_mixed_rate_affine_blocks_preserve_written_order(testCase)
    % Coefficient concatenation sees the final row and every rectangular entry.
    tests.infrastructure.verify_tensor_transform(testCase,"pdvar", ...
        @(x) cat(2,x,2*x-3),"mixed");
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function test_lower_degree_blocks_elevated_coefficient_wise(testCase)
    % Lower-degree blocks are elevated before coefficient-wise concatenation.
    P = pdvar(1, {[0 1]});
    B = pdmat({[0 1]}, {10, 20, 30}, Degree=2);
    cp = P.coeffs(1);

    C = [P, B];

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyEqual(size(C), [1 2]);
    tests.infrastructure.verify_expr(testCase, C.coeffs(1), { ...
        [cp{1}, 10], ...
        [0.5 * cp{1} + 0.5 * cp{2}, 20], ...
        [cp{2}, 30]});
end

function test_affine_sdpvar_blocks_promote_degree_0(testCase)
    % Affine sdpvar blocks promote to degree-0 coefficient data.
    P = pdvar(2, 1, {[0 1]}, "full");
    X = sdpvar(2, 1, 'full');
    cp = P.coeffs(1);

    C = [P, X];

    testCase.verifyEqual(size(C), [2 2]);
    tests.infrastructure.verify_expr(testCase, C.coeffs(1), {[cp{1}, X], [cp{2}, X]});
end

function test_ordinary_coefficient_rows_broadcast_across(testCase)
    % Ordinary coefficient rows should broadcast across derivative rate vertices.
    P = pdvar(2, 1, {[0 1]}, "full");
    D = rhodiff(P, [-1 2]);
    cp = P.coeffs(1);
    cd = D.coeffs(1);

    C = [D, P];
    cc = C.coeffs(1);

    testCase.verifyEqual(size(C), [2 2]);
    testCase.verifyEqual(C.Degree, 1);
    testCase.verifyFalse(C.IsContinuous);
    testCase.verifyEqual(C.RateBounds, [-1 2]);
    testCase.verifyEqual(size(cc), [2 2]);
    tests.infrastructure.verify_expr(testCase, cc(1, :), {[cd{1, 1}, cp{1}], [cd{1, 1}, cp{2}]});
    tests.infrastructure.verify_expr(testCase, cc(2, :), {[cd{2, 1}, cp{1}], [cd{2, 1}, cp{2}]});
end
