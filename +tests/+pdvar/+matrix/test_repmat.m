function tests = test_repmat
    % Public pdvar.repmat behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_vertical_replication_mixed(testCase)
    % Nonuniform tensor cells and mixed rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) repmat(x,[2 1]), "mixed");
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdvar", @(x) repmat(x, 2, 3));
end

function test_invalid_arguments_leave_source_unchanged(testCase)
    A=tests.infrastructure.fixture("pdvar",true);
    saved=A.LocalValues;
    testCase.verifyError(@() repmat(A,[1 2 3]),'pdvar:InvalidRepmat');
    testCase.verifyEqual(A.LocalValues,saved);
end
