function tests = test_le
    % Public pdvar.le behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_fixed_rate_constraint_sign_and_order(testCase)
    % A fixed vertex is still a rate row, including in the final physical cell.
    P = pdvar(2,{[0 2 5],[-3 1 6]},'symmetric',Degree=[1 2]);
    D = rhodiff(P,[3 3;-2 -2]);
    M = [2 -3;-3 7];
    C = D <= M;
    index = 0;
    for subs = [1 1;1 2;2 1;2 2]'
        c = D.coeffs(subs');
        for k = 1:size(c,2)
            index = index+1;
            tests.infrastructure.verify_expr(testCase, ...
                sdpvar(C.Constraints{index}),-1*(c{k}-M));
        end
    end
    testCase.verifyEqual(numel(C.Constraints),index);
    testCase.verifyEqual(C.Residual.NumRateRows,1);
end

function test_function_only_comparison_rejected_in_both_orders(testCase)
    % Inequality dispatch cannot treat placeholder coefficients as known evidence.
    P = pdvar(1,[0 2 5],Degree=2);
    F = pdmat([0 2 5],@(r) r);
    testCase.verifyError(@() P <= F,'pdvar:FunctionOnlyAlgebra');
    testCase.verifyError(@() F <= P,'pdvar:FunctionOnlyAlgebra');
end

function test_residual_signs_and_operand_order(testCase)
    A = tests.infrastructure.fixture("pdvar", false);
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
    testCase.verifyError(@() A <= ones(3), 'pdvar:InvalidSubtraction');
end
