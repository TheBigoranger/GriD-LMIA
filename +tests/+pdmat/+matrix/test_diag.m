function tests = test_diag
    % Public pdmat.diag behavioral contracts.
    tests = functiontests(localfunctions);
end
function test_rectangular_tensor_maps_with_fixed_and_mixed_rates(testCase)
    % Global polynomial derivatives remain continuous after known-data remapping.
    % Zero-degree axes and one fixed rate row still retain every coefficient.
    for mode = ["ordinary", "fixed", "mixed"]
        tests.infrastructure.verify_tensor_transform(testCase, "pdmat", ...
            @(x) diag(x,1), mode, @(x) diag(x,1), true);
    end
end
function test_function_only_transform_rejected_without_source_change(testCase)
    % Matching payload size cannot turn exact-only data into coefficients.
    F = pdmat({[0 2 5], [-1 3]}, ...
        @(x,y) [x+y, x-y, 1; x*y, y^2, 2*x]);
    saved = F.LocalValues;
    testCase.verifyError(@() diag(F), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyEqual(F.LocalValues, saved);
    testCase.verifyEqual(F.evaluate([.5 2]), [2.5 -1.5 1; 1 4 1]);
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdmat", @(x) diag(x));
end

function test_invalid_arguments_leave_source_unchanged(testCase)
    A=tests.infrastructure.fixture("pdmat",true);
    saved=A.LocalValues;
    testCase.verifyError(@() diag(A,4),'pdmat:InvalidDiag');
    testCase.verifyEqual(A.LocalValues,saved);
end
