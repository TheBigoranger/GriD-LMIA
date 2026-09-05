function tests = test_blkdiag
    % Behavioral regressions for pdmat.blkdiag.
    tests = functiontests(localfunctions);
end
function test_function_only_block_operands_rejected(testCase)
    % Every operand position must provide real coefficient evidence.
    F = pdmat([0 1], @(x) 1+x);
    A = pdmat([0 1], {1,2}, Degree=1);
    calls = {@() blkdiag(F,A), @() blkdiag(A,F), @() blkdiag(F,0), @() blkdiag(0,F)};
    for k = 1:numel(calls)
        testCase.verifyError(calls{k}, "pdmat:FunctionOnlyAlgebra");
    end
end

function test_tensor_refinement_degree_alignment_and_block_order(testCase)
    % Distinct polynomials prevent constant blocks from hiding alignment errors.
    f = @(x,y) [x^2+y; x*y];
    g = @(x,y) [x-y^2, 2*x; y^2, -3+y];
    A = pdmat({[0 .5 2], [-1 3]}, f, Degree=[2 1]);
    B = pdmat({[0 2], [-1 0 3]}, g, Degree=[1 2]);
    C = blkdiag(A, B);
    testCase.verifyEqual(C.Degree, [2 2]);
    testCase.verifyEqual(C.GridInfo.Vectors, {[0 .5 2], [-1 0 3]});
    for x = [0 .25 .5 1.25 2]
        for y = [-1 -.5 0 1.5 3]
            expected = blkdiag(f(x,y), g(x,y));
            testCase.verifyEqual(C.evaluate([x y]), expected, AbsTol=1e-10);
        end
    end
    testCase.verifyEmpty(C.FunctionHandle);
end

function test_blkdiag_align_grids_elevate_degree_accept(testCase)
    % blkdiag should align grids, elevate degree, and accept numeric blocks.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);
    B = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);

    C = blkdiag(A, 5, B);

    testCase.verifyEqual(size(C), [3 3]);
    testCase.verifyEqual(C.GridInfo.Vectors{1}, [0 0.5 1]);
    tests.infrastructure.verify_coeff(testCase, C, 1, {
        diag([1 5 10]), ...
        diag([1.5 5 20])
        });
    tests.infrastructure.verify_coeff(testCase, C, 2, {
        diag([1.5 5 20]), ...
        diag([2 5 30])
        });
end
