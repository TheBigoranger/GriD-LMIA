function tests = test_mean
    % Public pdvar.mean behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_multi_dimension_average_mixed(testCase)
    % Nonuniform tensor cells and mixed rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) mean(x,[2 3 1]), "mixed", @(x) mean(mean(x,2),1));
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdvar", @(x) mean(x, 1));
end

function test_invalid_arguments_leave_source_unchanged(testCase)
    A=tests.infrastructure.fixture("pdvar",true);
    saved=A.LocalValues;
    testCase.verifyError(@() mean(A,[1 1]),'pdvar:InvalidMean');
    testCase.verifyEqual(A.LocalValues,saved);
end
