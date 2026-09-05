function tests = test_flip
    % Public pdvar.flip behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_default_axis_reversal_ordinary(testCase)
    % Nonuniform tensor cells and ordinary rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) flip(x), "ordinary");
end

function test_tensor_default_axis_reversal_fixed(testCase)
    % Nonuniform tensor cells and fixed rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) flip(x), "fixed");
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdvar", @(x) flip(x, 2));
    A=tests.infrastructure.fixture("pdvar",false);
    testCase.verifyError(@() flip(A,0),"pdvar:InvalidFlip");
end
