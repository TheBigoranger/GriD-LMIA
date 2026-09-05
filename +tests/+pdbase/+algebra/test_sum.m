function tests = test_sum
    % Public pdbase.sum behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_rectangular_tensor_zero_degree_axis(testCase)
    % Every nonuniform tensor cell retains its complete asymmetric matrix map.
    tests.infrastructure.verify_tensor_transform(testCase, "pdbase", ...
        @(x) sum(x, [1 2]), "ordinary");
end

function test_fixed_rate_tensor_preserves_derivative_state(testCase)
    % A single fixed-rate row remains derivative evidence through the map.
    tests.infrastructure.verify_tensor_transform(testCase, "pdbase", ...
        @(x) sum(x, [1 2]), "fixed");
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdbase", @(x) sum(x, 2));
end

function test_invalid_arguments_leave_source_unchanged(testCase)
    A=tests.infrastructure.fixture("pdbase",true);
    saved=A.LocalValues;
    testCase.verifyError(@() sum(A,"rows"),'pdbase:InvalidSum');
    testCase.verifyEqual(A.LocalValues,saved);
end
