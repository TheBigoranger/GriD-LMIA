function tests = test_vec
    % Public pdbase.vec behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_rectangular_tensor_zero_degree_axis(testCase)
    % Every nonuniform tensor cell retains its complete asymmetric matrix map.
    tests.infrastructure.verify_tensor_transform(testCase, "pdbase", ...
        @(x) vec(x), "ordinary", @(x) x(:));
end

function test_fixed_rate_tensor_preserves_derivative_state(testCase)
    % A single fixed-rate row remains derivative evidence through the map.
    tests.infrastructure.verify_tensor_transform(testCase, "pdbase", ...
        @(x) vec(x), "fixed", @(x) x(:));
end

function test_all_cells_and_rate_rows(testCase)
    % MATLAB column-major vectorization is the independent reference.
    for rates = [false true]
        A = tests.infrastructure.fixture("pdbase", rates);
        B = vec(A);
        for cellIndex = 1:2
            input = A.coeffs(cellIndex);
            expected = cellfun(@(x) x(:), input, 'UniformOutput', false);
            tests.infrastructure.verify_expr(testCase, B.coeffs(cellIndex), expected);
        end
        testCase.verifyEqual(B.MatrixSize, [4 1]);
    end
end
