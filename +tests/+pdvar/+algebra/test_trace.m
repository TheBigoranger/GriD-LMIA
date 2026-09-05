function tests = test_trace
    % Public pdvar.trace behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_rectangular_tensor_diagonal_sum_ordinary(testCase)
    % Nonuniform tensor cells and ordinary rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) trace(x), "ordinary", @(x) sum(diag(x)));
end

function test_rectangular_tensor_diagonal_sum_fixed(testCase)
    % Nonuniform tensor cells and fixed rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) trace(x), "fixed", @(x) sum(diag(x)));
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdvar", @(x) trace(x));
end
