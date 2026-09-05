function tests = test_subsref
    % Behavioral regressions for pdmat.subsref.
    tests = functiontests(localfunctions);
end
function test_function_only_slices_rejected_but_metadata_available(testCase)
    % Matrix slicing transforms coefficients, while dot inspection is legal.
    F = pdmat([0 1], @(x) [x 1+x; 2*x 3-x]);
    calls = {@() F(:,1), @() F(1:4), @() F([true false],:), @() F(:,:)};
    for k = 1:numel(calls)
        testCase.verifyError(calls{k}, "pdmat:FunctionOnlyAlgebra");
    end
    testCase.verifyEqual(F.MatrixSize, [2 2]);
    testCase.verifyEqual(F.FunctionHandle(.25), [.25 1.25; .5 2.75]);
end

function test_matrix_indexing_slice_payloads_while_dot(testCase)
    % Matrix indexing should slice payloads while dot access stays available.
    A = pdmat({[0 1]}, {
        [1 2 3; 4 5 6], ...
        [10 20 30; 40 50 60]
        }, Degree=1);

    lastCol = A(:, end);
    topTail = A(1, 2:3);
    firstRow = A([true false], :);
    coeffs = A.coeffs(1);
    nestedDegree = A(:, 1).Degree;

    testCase.verifyEqual(size(lastCol), [2 1]);
    testCase.verifyEqual(size(topTail), [1 2]);
    testCase.verifyEqual(size(firstRow), [1 3]);
    testCase.verifyEqual(coeffs{1}, [1 2 3; 4 5 6]);
    testCase.verifyEqual(nestedDegree, 1);
    tests.infrastructure.verify_coeff(testCase, lastCol, 1, {[3; 6], [30; 60]});
    tests.infrastructure.verify_coeff(testCase, topTail, 1, {[2 3], [20 30]});
    tests.infrastructure.verify_coeff(testCase, firstRow, 1, {[1 2 3], [10 20 30]});
end

function test_reordered_repeated_and_logical_selectors(testCase)
    A = tests.infrastructure.fixture("pdmat", true);
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
