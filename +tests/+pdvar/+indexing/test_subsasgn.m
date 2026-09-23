function tests = test_subsasgn
    % Behavioral regressions for pdvar.subsasgn.
    tests = functiontests(localfunctions);
end

function test_fixed_tensor_assignment_keeps_unselected_affine_entries(testCase)
    % Reversed row/column selection edits every fixed-rate leaf in written order.
    P = pdvar(2,3,{[0 2 5],[-3 1 6]},'full',Degree=[1 2]);
    D = rhodiff(P,[3 3;-2 -2]);
    saved = D.LocalValues;
    R = D;
    R([2 1],[3 1]) = [11 -13;17 19];
    for subs = [1 1;1 2;2 1;2 2]'
        expected = D.coeffs(subs');
        for k = 1:numel(expected)
            expected{k}([2 1],[3 1]) = [11 -13;17 19];
        end
        tests.infrastructure.verify_expr(testCase,R.coeffs(subs'),expected);
    end
    testCase.verifyEqual(D.LocalValues,saved);
    testCase.verifyEqual(R.NumRateRows,1);
    testCase.verifyEqual(R.RateBounds,D.RateBounds);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function test_subscript_assignment_accept_numeric_constants_pdvar(testCase)
    % Subscript assignment should accept numeric constants and pdvar blocks.
    P = pdvar(2, {[0 1]}, "full");
    cp = P.coeffs(1);
    P(:, 2) = 5;

    tests.infrastructure.verify_expr(testCase, P.coeffs(1), { ...
        [cp{1}(:, 1), 5 * ones(2, 1)], ...
        [cp{2}(:, 1), 5 * ones(2, 1)]});

    B = pdmat({[0 1]}, {[10 20], [30 40], [50 60]}, Degree=2);
    P(1, :) = B;

    testCase.verifyEqual(P.Degree, 2);
    tests.infrastructure.verify_expr(testCase, P.coeffs(1), { ...
        [10 20; cp{1}(2, 1), 5], ...
        [30 40; 0.5 * cp{1}(2, 1) + 0.5 * cp{2}(2, 1), 5], ...
        [50 60; cp{2}(2, 1), 5]});
end

function test_assignment_same_ordinary_rate_row_broadcast(testCase)
    % Assignment should use the same ordinary/rate-row broadcast as affine ops.
    P = pdvar(2, {[0 1]}, "full");
    D = rhodiff(pdvar(1, {[0 1]}), [-1 2]);
    cp = P.coeffs(1);
    cd = D.coeffs(1);

    P(1, 1) = D;
    cc = P.coeffs(1);

    testCase.verifyEqual(P.Degree, 1);
    testCase.verifyEqual(P.Continuity, Inf);
    testCase.verifyTrue(P.IsContinuous);
    testCase.verifyEqual(size(cc), [2 2]);
    tests.infrastructure.verify_expr(testCase, cc(1, :), { ...
        [cd{1, 1}, cp{1}(1, 2); cp{1}(2, 1), cp{1}(2, 2)], ...
        [cd{1, 1}, cp{2}(1, 2); cp{2}(2, 1), cp{2}(2, 2)]});
    tests.infrastructure.verify_expr(testCase, cc(2, :), { ...
        [cd{2, 1}, cp{1}(1, 2); cp{1}(2, 1), cp{1}(2, 2)], ...
        [cd{2, 1}, cp{2}(1, 2); cp{2}(2, 1), cp{2}(2, 2)]});
end

function test_assigning_ordinary_blocks_into_derivative_rows(testCase)
    % Assigning ordinary blocks into derivative rows should broadcast by row.
    P = pdvar(2, {[0 1]}, "full");
    D = rhodiff(P, [-1 2]);
    cp = P.coeffs(1);
    cd = D.coeffs(1);

    D(1, 1) = P(2, 2);
    cc = D.coeffs(1);

    testCase.verifyEqual(D.Degree, 1);
    testCase.verifyEqual(D.Continuity, Inf);
    testCase.verifyTrue(D.IsContinuous);
    testCase.verifyEqual(size(cc), [2 2]);
    tests.infrastructure.verify_expr(testCase, cc(1, :), { ...
        [cp{1}(2, 2), cd{1, 1}(1, 2); cd{1, 1}(2, 1), cd{1, 1}(2, 2)], ...
        [cp{2}(2, 2), cd{1, 1}(1, 2); cd{1, 1}(2, 1), cd{1, 1}(2, 2)]});
    tests.infrastructure.verify_expr(testCase, cc(2, :), { ...
        [cp{1}(2, 2), cd{2, 1}(1, 2); cd{2, 1}(2, 1), cd{2, 1}(2, 2)], ...
        [cp{2}(2, 2), cd{2, 1}(1, 2); cd{2, 1}(2, 1), cd{2, 1}(2, 2)]});
end

function test_assignment_preserves_unselected_entries(testCase)
    A=tests.infrastructure.fixture("pdvar", true);
    saved=A.LocalValues;
    B=A;
    B([2 1],2)=[101;103];
    for cellIndex=1:2
        expected=A.coeffs(cellIndex);
        for k=1:numel(expected)
            expected{k}([2 1],2)=[101;103];
        end
        tests.infrastructure.verify_expr(testCase,B.coeffs(cellIndex),expected);
    end
    testCase.verifyEqual(A.LocalValues,saved);
    testCase.verifyEqual(B.NumRateRows,2);
end
