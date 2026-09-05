function tests = test_transpose
    % Public pdvar.transpose behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_rectangular_tensor_transpose_ordinary(testCase)
    % Nonuniform tensor cells and ordinary rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) transpose(x), "ordinary");
end

function test_rectangular_tensor_transpose_fixed(testCase)
    % Nonuniform tensor cells and fixed rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) transpose(x), "fixed");
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdvar", @(x) transpose(x));
end
