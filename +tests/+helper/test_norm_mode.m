function tests = test_norm_mode
    % Public helper.norm_mode behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_missing_and_character_matrix_are_rejected(testCase)
    % Neither a missing scalar nor a character matrix is scalar mode text.
    testCase.verifyError(@() helper.normMode(string(missing), 'fixture'), ...
        'fixture:InvalidValidationMode');
    testCase.verifyError(@() helper.normMode(['fast'; 'FAST'], 'fixture'), ...
        'fixture:InvalidValidationMode');
end

function test_whitespace_is_not_silently_trimmed(testCase)
    % Accept exact case variants, but preserve the explicit option vocabulary.
    testCase.verifyEqual(helper.normMode('fAsT', 'pdlmi'), "fast");
    testCase.verifyError(@() helper.normMode(" fast", 'pdlmi'), ...
        'pdlmi:InvalidValidationMode');
    testCase.verifyError(@() helper.normMode("strict ", 'pdvar'), ...
        'pdvar:InvalidValidationMode');
end

function test_modes_and_caller_errors(testCase)
    testCase.verifyEqual(helper.normMode('STRICT','fixture'), "strict");
    testCase.verifyEqual(helper.normMode("Fast",'fixture'), "fast");
    for input = {[], 3, ["fast" "strict"], '', "unknown"}
        testCase.verifyError(@() helper.normMode(input{1},'fixture'), 'fixture:InvalidValidationMode');
    end
end
