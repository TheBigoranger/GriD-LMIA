function tests = test_vec
    % Public pdvar.vec behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_column_major_vectorization_ordinary(testCase)
    % Nonuniform tensor cells and ordinary rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) vec(x), "ordinary", @(x) x(:));
end

function test_tensor_column_major_vectorization_fixed(testCase)
    % Nonuniform tensor cells and fixed rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) vec(x), "fixed", @(x) x(:));
end

function test_all_cells_and_rate_rows(testCase)
    % MATLAB column-major vectorization is the independent reference.
    for rates = [false true]
        A = tests.infrastructure.fixture("pdvar", rates);
        B = vec(A);
        for cellIndex = 1:2
            input = A.coeffs(cellIndex);
            expected = cellfun(@(x) x(:), input, 'UniformOutput', false);
            tests.infrastructure.verify_expr(testCase, B.coeffs(cellIndex), expected);
        end
        testCase.verifyEqual(B.MatrixSize, [4 1]);
    end
end
