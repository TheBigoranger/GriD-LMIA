function tests = test_ctranspose
    % Public pdvar.ctranspose behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_rectangular_tensor_adjoint_ordinary(testCase)
    % Nonuniform tensor cells and ordinary rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) ctranspose(x), "ordinary");
end

function test_rectangular_tensor_adjoint_fixed(testCase)
    % Nonuniform tensor cells and fixed rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) ctranspose(x), "fixed");
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdvar", @(x) ctranspose(x));
end
