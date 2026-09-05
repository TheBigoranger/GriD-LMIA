function tests = test_api_gate
    % Verify each traceability failure separately from package behavior.
    tests = functiontests(localfunctions);
end

function test_valid_contract(testCase)
    [result, map, api] = fixture();
    testCase.verifyWarningFree(@() tests.infrastructure.api_gate(result, map, api));
end

function test_missing_and_stale_api(testCase)
    [result, map, api] = fixture();
    testCase.verifyError(@() tests.infrastructure.api_gate(result, map, [api; "pdmat" "plus"]), 'tests:ApiMismatch');
    testCase.verifyError(@() tests.infrastructure.api_gate(result, map, strings(0,2)), 'tests:ApiMismatch');
end

function test_stale_name_and_wrong_owner(testCase)
    [result, map, api] = fixture();
    map.Tests = 'tests.pdmat.polynomial.test_elevate/test_missing';
    testCase.verifyError(@() tests.infrastructure.api_gate(result, map, api), 'tests:MissingTest');
    map.Tests = 'tests.pdbase.polynomial.test_elevate/test_known_coefficients';
    testCase.verifyError(@() tests.infrastructure.api_gate(result, map, api), 'tests:WrongOwner');
end

function test_failed_and_incomplete_results(testCase)
    [result, map, api] = fixture();
    result.Passed = false;
    result.Failed = true;
    testCase.verifyError(@() tests.infrastructure.api_gate(result, map, api), 'tests:UnverifiedApi');
    result.Failed = false;
    result.Incomplete = true;
    testCase.verifyError(@() tests.infrastructure.api_gate(result, map, api), 'tests:UnverifiedApi');
end

function test_missing_contract_and_duplicate_registration(testCase)
    [result, map, api] = fixture();
    testCase.verifyError(@() tests.infrastructure.api_gate(result, [map map], api), 'tests:DuplicateApi');
    map.Oracle = '';
    testCase.verifyError(@() tests.infrastructure.api_gate(result, map, api), 'tests:MissingContract');
end

function [result, map, api] = fixture()
    name = 'tests.pdmat.polynomial.test_elevate/test_known_coefficients';
    result = struct('Name', name, 'Passed', true, 'Failed', false, 'Incomplete', false);
    map = struct('Owner', 'pdmat', 'Method', 'elevate', 'Tests', name, ...
        'Contract', 'Retain polynomial on elevation.', 'Oracle', 'Binomial incidence.', ...
        'Invalid', 'Negative increment rejected.');
    api = ["pdmat", "elevate"];
end

function test_duplicate_result_names_and_empty_mapping_rejected(testCase)
    % A passing result must identify exactly one executed behavioral case.
    [result, map, api] = fixture();
    testCase.verifyError(@() tests.infrastructure.api_gate([result result], map, api), ...
        'tests:MissingTest');
    map.Tests = {};
    testCase.verifyError(@() tests.infrastructure.api_gate(result, map, api), ...
        'tests:MissingTest');
end

function test_missing_invalid_evidence_and_partial_pass_rejected(testCase)
    % Missing rejection evidence cannot be hidden by a valid oracle or pass flag.
    [result, map, api] = fixture();
    map.Invalid = '';
    testCase.verifyError(@() tests.infrastructure.api_gate(result, map, api), ...
        'tests:MissingContract');
    [result, map, api] = fixture();
    result.Incomplete = true;
    testCase.verifyError(@() tests.infrastructure.api_gate(result, map, api), ...
        'tests:UnverifiedApi');
end
