function tests = test_flipud
    % Public pdvar.flipud behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_row_reversal_ordinary(testCase)
    % Nonuniform tensor cells and ordinary rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) flipud(x), "ordinary");
end

function test_tensor_row_reversal_fixed(testCase)
    % Nonuniform tensor cells and fixed rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) flipud(x), "fixed");
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdvar", @(x) flipud(x));
end
