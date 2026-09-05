function tests = test_subsref
    % Behavioral regressions for pdvar.subsref.
    tests = functiontests(localfunctions);
end

function test_fixed_rate_tensor_slice_preserves_order_and_identity(testCase)
    % Repeated rectangular selectors retain a single active fixed-rate row.
    P = pdvar(2,3,{[0 2 5],[-3 1 6]},'full',Degree=[1 2]);
    D = rhodiff(P,[3 3;-2 -2]);
    R = D([2 1 2],[3 1]);
    for subs = [1 1;1 2;2 1;2 2]'
        c = D.coeffs(subs');
        expected = cellfun(@(x) x([2 1 2],[3 1]),c,'UniformOutput',false);
        tests.infrastructure.verify_expr(testCase,R.coeffs(subs'),expected);
    end
    testCase.verifyEqual(R.NumRateRows,1);
    testCase.verifyEqual(R.MatrixSize,[3 2]);
    testCase.verifyEqual(R.RateBounds,D.RateBounds);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function test_matrix_indexing_slice_payloads_while_dot(testCase)
    % Matrix indexing should slice payloads while dot access stays available.
    P = pdvar(2, 3, {[0 1]}, "full");
    cp = P.coeffs(1);

    lastCol = P(:, end);
    topTail = P(1, 2:3);
    firstRow = P([true false], :);
    coeffs = P.coeffs(1);
    nestedDegree = P(:, 1).Degree;

    testCase.verifyEqual(size(lastCol), [2 1]);
    testCase.verifyEqual(size(topTail), [1 2]);
    testCase.verifyEqual(size(firstRow), [1 3]);
    testCase.verifyEqual(nestedDegree, 1);
    tests.infrastructure.verify_expr(testCase, coeffs, cp);
    tests.infrastructure.verify_expr(testCase, lastCol.coeffs(1), {cp{1}(:, 3), cp{2}(:, 3)});
    tests.infrastructure.verify_expr(testCase, topTail.coeffs(1), {cp{1}(1, 2:3), cp{2}(1, 2:3)});
    tests.infrastructure.verify_expr(testCase, firstRow.coeffs(1), {cp{1}(1, :), cp{2}(1, :)});
end

function test_reordered_repeated_and_logical_selectors(testCase)
    A = tests.infrastructure.fixture("pdvar", true);
    saved=A.LocalValues;
    selections = {A([2 1 2],[2 1]), A([true false],[false true])};
    for cellIndex=1:2
        c=A.coeffs(cellIndex);
        tests.infrastructure.verify_expr(testCase,selections{1}.coeffs(cellIndex), ...
            cellfun(@(x) x([2 1 2],[2 1]),c,'UniformOutput',false));
        tests.infrastructure.verify_expr(testCase,selections{2}.coeffs(cellIndex), ...
            cellfun(@(x) x(1,2),c,'UniformOutput',false));
    end
    testCase.verifyEqual(A.LocalValues,saved);
end
