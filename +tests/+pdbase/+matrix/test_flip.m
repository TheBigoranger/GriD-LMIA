function tests = test_flip
    % Public pdbase.flip behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_rectangular_tensor_zero_degree_axis(testCase)
    % Every nonuniform tensor cell retains its complete asymmetric matrix map.
    tests.infrastructure.verify_tensor_transform(testCase, "pdbase", ...
        @(x) flip(x, 1), "ordinary");
end

function test_fixed_rate_tensor_preserves_derivative_state(testCase)
    % A single fixed-rate row remains derivative evidence through the map.
    tests.infrastructure.verify_tensor_transform(testCase, "pdbase", ...
        @(x) flip(x, 1), "fixed");
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdbase", @(x) flip(x, 2));
    A=tests.infrastructure.fixture("pdbase",false);
    testCase.verifyError(@() flip(A,0),"pdbase:InvalidFlip");
end
