function tests = test_diag
    % Public pdvar.diag behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_offset_diagonal_mixed(testCase)
    % Nonuniform tensor cells and mixed rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) diag(x,1), "mixed");
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdvar", @(x) diag(x));
end

function test_invalid_arguments_leave_source_unchanged(testCase)
    A=tests.infrastructure.fixture("pdvar",true);
    saved=A.LocalValues;
    testCase.verifyError(@() diag(A,4),'pdvar:InvalidDiag');
    testCase.verifyEqual(A.LocalValues,saved);
end
