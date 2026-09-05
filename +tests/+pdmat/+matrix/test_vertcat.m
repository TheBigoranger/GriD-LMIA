function tests = test_vertcat
    % Public pdmat.vertcat behavioral contracts.
    tests = functiontests(localfunctions);
end
function test_function_only_block_operands_rejected(testCase)
    % Every operand position must provide real coefficient evidence.
    F = pdmat([0 1], @(x) 1+x);
    A = pdmat([0 1], {1,2}, Degree=1);
    calls = {@() vertcat(F,A), @() vertcat(A,F), @() vertcat(F,0), @() vertcat(0,F)};
    for k = 1:numel(calls)
        testCase.verifyError(calls{k}, "pdmat:FunctionOnlyAlgebra");
    end
end

function test_tensor_refinement_degree_alignment_and_block_order(testCase)
    % Distinct polynomials prevent constant blocks from hiding alignment errors.
    f = @(x,y) [x^2+y, x*y];
    g = @(x,y) [x-y^2, 2*x];
    A = pdmat({[0 .5 2], [-1 3]}, f, Degree=[2 1]);
    B = pdmat({[0 2], [-1 0 3]}, g, Degree=[1 2]);
    C = vertcat(A, B);
    testCase.verifyEqual(C.Degree, [2 2]);
    testCase.verifyEqual(C.GridInfo.Vectors, {[0 .5 2], [-1 0 3]});
    for x = [0 .25 .5 1.25 2]
        for y = [-1 -.5 0 1.5 3]
            expected = vertcat(f(x,y), g(x,y));
            testCase.verifyEqual(C.evaluate([x y]), expected, AbsTol=1e-10);
        end
    end
    testCase.verifyEmpty(C.FunctionHandle);
end

function test_native_block_order_all_rows(testCase)
    A=tests.infrastructure.fixture("pdmat",true);
    testCase.verifyError(@() vertcat(A,ones(3)),"pdmat:InvalidConcatenation");
    B=vertcat(A,7*A);
    for cellIndex=1:2
        c=A.coeffs(cellIndex);
        expected=cellfun(@(x) cat(1,x,7*x),c,'UniformOutput',false);
        tests.infrastructure.verify_expr(testCase,B.coeffs(cellIndex),expected);
    end
end
