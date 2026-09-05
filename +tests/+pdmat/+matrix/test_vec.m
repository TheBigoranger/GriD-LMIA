function tests = test_vec
    % Public pdmat.vec behavioral contracts.
    tests = functiontests(localfunctions);
end
function test_rectangular_tensor_maps_with_fixed_and_mixed_rates(testCase)
    % Global polynomial derivatives remain continuous after known-data remapping.
    % Zero-degree axes and one fixed rate row still retain every coefficient.
    for mode = ["ordinary", "fixed", "mixed"]
        tests.infrastructure.verify_tensor_transform(testCase, "pdmat", ...
            @(x) vec(x), mode, @(x) x(:), true);
    end
end
function test_function_only_transform_rejected_without_source_change(testCase)
    % Matching payload size cannot turn exact-only data into coefficients.
    F = pdmat({[0 2 5], [-1 3]}, ...
        @(x,y) [x+y, x-y, 1; x*y, y^2, 2*x]);
    saved = F.LocalValues;
    testCase.verifyError(@() vec(F), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyEqual(F.LocalValues, saved);
    testCase.verifyEqual(F.evaluate([.5 2]), [2.5 -1.5 1; 1 4 1]);
end

function test_all_cells_and_rate_rows(testCase)
    % MATLAB column-major vectorization is the independent reference.
    for rates = [false true]
        A = tests.infrastructure.fixture("pdmat", rates);
        B = vec(A);
        for cellIndex = 1:2
            input = A.coeffs(cellIndex);
            expected = cellfun(@(x) x(:), input, 'UniformOutput', false);
            tests.infrastructure.verify_expr(testCase, B.coeffs(cellIndex), expected);
        end
        testCase.verifyEqual(B.MatrixSize, [4 1]);
    end
end
