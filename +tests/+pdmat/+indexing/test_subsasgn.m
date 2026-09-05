function tests = test_subsasgn
    % Behavioral regressions for pdmat.subsasgn.
    tests = functiontests(localfunctions);
end
function test_function_only_assignment_operands_rejected(testCase)
    % Both the destination and source block need coefficient evidence.
    F = pdmat([0 1], @(x) [x 1+x; 2*x 3-x]);
    A = pdmat([0 1], {eye(2), 2*eye(2)}, Degree=1);
    selector = substruct('()', {':', ':'});
    saved = A.LocalValues;
    testCase.verifyError(@() subsasgn(F,selector,A), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() subsasgn(A,selector,F), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() subsasgn(F,selector,0), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyEqual(A.LocalValues, saved);
end

function test_subscript_assignment_accept_numeric_constants_pdmat(testCase)
    % Subscript assignment should accept numeric constants and pdmat blocks.
    A = pdmat({[0 1]}, {zeros(2), 2 * ones(2)}, Degree=1);
    A(:, 2) = 5;

    tests.infrastructure.verify_coeff(testCase, A, 1, {
        [0 5; 0 5], ...
        [2 5; 2 5]
        });

    B = pdmat({[0 1]}, {[10 20], [30 40], [50 60]}, Degree=2);
    A(1, :) = B;

    testCase.verifyEqual(A.Degree, 2);
    tests.infrastructure.verify_coeff(testCase, A, 1, {
        [10 20; 0 5], ...
        [30 40; 1 5], ...
        [50 60; 2 5]
        });
end

function test_assignment_preserves_unselected_entries(testCase)
    A=tests.infrastructure.fixture("pdmat", true);
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
