function tests = test_validation_mode
    %TEST_VALIDATION_MODE Transient representative/full storage validation.
    tests = functiontests(localfunctions);
end

function testDefaultEqualsExplicitFastAndStrictForValidData(testCase)
    % Valid normalized storage has identical public state in every mode.
    grid = {[0 1 2]};
    vals = {{1, 2}, {2, 3}};

    implicit = pdbase(grid, [1 1], 1, vals);
    fast = pdbase(grid, [1 1], 1, vals, ValidationMode="FAST");
    strict = pdbase(grid, [1 1], 1, vals, ValidationMode='Strict');

    testCase.verifyEqual(implicit.GridInfo, fast.GridInfo);
    testCase.verifyEqual(implicit.LocalValues, fast.LocalValues);
    testCase.verifyEqual(fast.LocalValues, strict.LocalValues);
    testCase.verifyFalse(isprop(implicit, "ValidationMode"));
end

function testFastSamplesFirstCellAndStrictChecksWholeTree(testCase)
    % Fast trusts later generated cells; strict remains the diagnostic mode.
    grid = {[0 1 2]};

    wrongCount = {{1, 2}, {3}};
    fast = pdbase(grid, [1 1], 1, wrongCount, ValidationMode="fast");
    testCase.verifyEqual(fast.LocalValues, wrongCount);
    testCase.verifyError(@() pdbase(grid, [1 1], 1, wrongCount, ...
        ValidationMode="strict"), "pdbase:InvalidCoefficientCell");

    wrongSize = {{eye(2), eye(2)}, {1, eye(2)}};
    fast = pdbase(grid, [2 2], 1, wrongSize, ValidationMode="fast");
    testCase.verifyEqual(fast.LocalValues, wrongSize);
    testCase.verifyError(@() pdbase(grid, [2 2], 1, wrongSize, ...
        ValidationMode="strict"), "pdbase:InvalidCoefficientPayload");

    mixedRows = {{1, 2}, {3, 4; 5, 6}};
    fast = pdbase(grid, [1 1], 1, mixedRows, ...
        RateBounds=[-1 1], ValidationMode="fast");
    testCase.verifyEqual(fast.LocalValues, mixedRows);
    testCase.verifyError(@() pdbase(grid, [1 1], 1, mixedRows, ...
        RateBounds=[-1 1], ValidationMode="strict"), ...
        "pdbase:InvalidCoefficientRows");
end

function testInvalidModesUseOwnerIdentifier(testCase)
    % Missing, nonscalar, nontext, empty, and unsupported modes are rejected.
    make = @(mode) pdbase({[0 1]}, [1 1], 0, {{1}}, ...
        ValidationMode=mode);
    bad = {42, ["fast", "strict"], string(missing), '', "sample"};
    for k = 1:numel(bad)
        testCase.verifyError(@() make(bad{k}), ...
            "pdbase:InvalidValidationMode");
    end
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, {{1}}, ...
        "ValidationMode"), "pdbase:InvalidValidationMode");
end
