function tests = test_chk
    %TEST_CHK Shared sanity predicate helper.
    tests = functiontests(localfunctions);
end

function testValidNumericPredicatesReturnInput(testCase)
    val = helper.chk([1 2], "test:InvalidValue", "bad value", ...
        "numeric", "real", "finite", "integer", "positive", "Size", [1, 2]);

    testCase.verifyEqual(val, [1 2]);
end

function testCellShapePredicateUsesCallerError(testCase)
    testCase.verifyError(@() helper.chk({1, 2}, "test:InvalidCell", "bad cell", ...
        "cell", "Numel", 3), "test:InvalidCell");
end

function testUnknownPredicateFailsAsValidatorBug(testCase)
    testCase.verifyError(@() helper.chk(1, "test:InvalidValue", "bad value", ...
        "not-a-predicate"), "helper:InvalidValidatorCall");
end
