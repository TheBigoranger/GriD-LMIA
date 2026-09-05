function tests = test_minus
    % Public pdvar.minus behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_refinement_and_anisotropic_subtraction(testCase)
    % Independent source evaluations check refinement and elevation together.
    P = pdvar(2,3,{[0 1 3],[-2 4]},'full',Degree=[1 0]);
    Q = pdvar(2,3,{[0 3],[-2 0 4]},'full',Degree=[0 2]);
    saved = P.LocalValues;
    R = P-Q;
    testCase.verifyEqual(R.GridInfo.Vectors,{[0 1 3],[-2 0 4]});
    testCase.verifyEqual(R.Degree,[1 2]);
    for x = [0 .4 1 2.3 3]
        for y = [-2 -1 0 1.7 4]
            tests.infrastructure.verify_expr(testCase,R.evaluate([x y]), ...
                P.evaluate([x y])-Q.evaluate([x y]));
        end
    end
    testCase.verifyEqual(P.LocalValues,saved);
end

function test_function_only_rejection_survives_cancelled_decision(testCase)
    % A proven zero decision must not turn a handle into coefficient evidence.
    P = pdvar(1,[0 2 5],Degree=2);
    Z = P-P;
    F = pdmat([0 2 5],@(r) r);
    testCase.verifyError(@() Z-F,'pdvar:FunctionOnlyAlgebra');
    testCase.verifyError(@() F-Z,'pdvar:FunctionOnlyAlgebra');
end

function test_complete_residual_in_both_orders(testCase)
    A = tests.infrastructure.fixture("pdvar", true);
    saved = A.LocalValues;
    constant = [2 -7;11 3];
    left = A - constant;
    right = constant - A;
    for cellIndex = 1:2
        c = A.coeffs(cellIndex);
        tests.infrastructure.verify_expr(testCase,left.coeffs(cellIndex), ...
            cellfun(@(x) x - constant,c,'UniformOutput',false));
        tests.infrastructure.verify_expr(testCase,right.coeffs(cellIndex), ...
            cellfun(@(x) constant - x,c,'UniformOutput',false));
    end
    testCase.verifyEqual(A.LocalValues,saved);
    testCase.verifyError(@() A - ones(3), 'pdvar:InvalidSubtraction');
end
