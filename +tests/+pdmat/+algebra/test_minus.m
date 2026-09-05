function tests = test_minus
    % Public pdmat.minus behavioral contracts.
    tests = functiontests(localfunctions);
end
function test_refined_tensor_subtraction_preserves_values(testCase)
    % Refine different axes while aligning unequal degrees componentwise.
    f = @(x,y) [x^2+y, x*y; 2*x-y, 1+y];
    g = @(x,y) [x-y^2, 2*x; y^2, -3+y];
    A = pdmat({[0 .5 2], [-1 3]}, f, Degree=[2 1]);
    B = pdmat({[0 2], [-1 0 3]}, g, Degree=[1 2]);
    C = A-B; R = B-A;
    testCase.verifyEqual(C.Degree, [2 2]);
    testCase.verifyEqual(C.GridInfo.Vectors, {[0 .5 2], [-1 0 3]});
    for x = [0 .25 .5 1.25 2]
        for y = [-1 -.5 0 1.5 3]
            testCase.verifyEqual(C.evaluate([x y]), f(x,y)-g(x,y), AbsTol=1e-10);
            testCase.verifyEqual(R.evaluate([x y]), g(x,y)-f(x,y), AbsTol=1e-10);
        end
    end
end

function test_function_only_cancellation_shortcuts_rejected(testCase)
    % Identical exact handles still provide no coefficient evidence.
    F = pdmat([0 1], @(x) [x 2*x; 3*x 1+x]);
    Z = pdmat([0 1], {zeros(2), zeros(2)}, Degree=1);
    saved = F.LocalValues;
    calls = {@() F - 0, @() 0 - F, @() F - F, ...
        @() F - Z, @() Z - F, @() F - 1, @() 1 - F};
    for k = 1:numel(calls)
        testCase.verifyError(calls{k}, "pdmat:FunctionOnlyAlgebra");
    end
    testCase.verifyEqual(F.LocalValues, saved);
end

function test_complete_residual_in_both_orders(testCase)
    A = tests.infrastructure.fixture("pdmat", true);
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
    testCase.verifyError(@() A - ones(3), 'pdmat:InvalidSubtraction');
end
