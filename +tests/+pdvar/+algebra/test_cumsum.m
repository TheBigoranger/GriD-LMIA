function tests = test_cumsum
    % Public pdvar.cumsum behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_reverse_column_accumulation_mixed(testCase)
    % Nonuniform tensor cells and mixed rate storage expose payload and row-order drift.
    tests.infrastructure.verify_tensor_transform(testCase, "pdvar", ...
        @(x) cumsum(x,2,"reverse"), "mixed", @(x) x*[1 0 0;1 1 0;1 1 1]);
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdvar", @(x) cumsum(x, 2, 'reverse'), ...
        @(x) fliplr(cumsum(fliplr(x), 2)));
end

function test_invalid_arguments_leave_source_unchanged(testCase)
    A=tests.infrastructure.fixture("pdvar",true);
    saved=A.LocalValues;
    testCase.verifyError(@() cumsum(A,0.5),'pdvar:InvalidCumsum');
    testCase.verifyEqual(A.LocalValues,saved);
end
