function tests = test_le
    % Public pdmat.le behavioral contracts.
    tests = functiontests(localfunctions);
end
function test_function_only_both_operand_orders_rejected(testCase)
    % Known comparisons may not certify placeholder coefficient matrices.
    F = pdmat([0 1], @(x) [1+x, 0; 0, 2-x]);
    testCase.verifyError(@() F <= 0, "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() 0 <= F, "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() F <= F, "pdmat:FunctionOnlyAlgebra");
end

function test_fixed_tensor_rate_rows_export_complete_signs(testCase)
    % Distinct derivative rows include both passing and failing coefficients.
    A = pdmat({[0 2 5], [-1 1 4]}, @(x,y) x^2+3*y^2, ...
        Degree=[2 2], RateBounds=[2 2; -3 5]);
    D = rhodiff(A);
    C = D <= 0;
    index = 0;
    expected = true;
    for subs = D.cells()'
        coeffs = D.coeffs(subs');
        testCase.verifyEqual(C.Residual.coeffs(subs'), coeffs, AbsTol=1e-10);
        for row = 1:size(coeffs,1)
            for k = 1:size(coeffs,2)
                index = index+1;
                expected = expected && (coeffs{row,k} <= 1e-10);
            end
        end
    end
    % Known Direct certificates reduce every tested coefficient to one logical.
    testCase.verifyEqual(index, 72);
    testCase.verifyEqual(C.Constraints, {expected});
    testCase.verifyEqual(C.Residual.NumRateRows, 2);
end

function test_residual_signs_and_operand_order(testCase)
    A = tests.infrastructure.fixture("pdmat", false);
    A = A + transpose(A);
    C = [2 -3;-3 7];
    left = A <= C;
    right = C <= A;
    testCase.verifyEqual(left.Relation,"<=");
    for cellIndex = 1:2
        c = A.coeffs(cellIndex);
        tests.infrastructure.verify_expr(testCase,left.Residual.coeffs(cellIndex), ...
            cellfun(@(x) x-C,c,'UniformOutput',false));
        tests.infrastructure.verify_expr(testCase,right.Residual.coeffs(cellIndex), ...
            cellfun(@(x) C-x,c,'UniformOutput',false));
    end
    testCase.verifyError(@() A <= ones(3), 'pdmat:InvalidSubtraction');
end
