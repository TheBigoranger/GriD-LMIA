function tests = test_chk
    %TEST_CHK Shared sanity predicate helper.
    tests = functiontests(localfunctions);
end

function testValidNumericPredicatesReturnInput(testCase)
    % Valid numeric predicate chains should return the original value.
    val = helper.chk([1 2], "test:InvalidValue", "bad value", ...
        "numeric", "real", "finite", "integer", "positive", "Size", [1, 2]);

    testCase.verifyEqual(val, [1 2]);
end

function testCellShapePredicateUsesCallerError(testCase)
    % Cell validation failures should preserve the caller's error ID.
    testCase.verifyError(@() helper.chk({1, 2}, "test:InvalidCell", "bad cell", ...
        "cell", "Numel", 3), "test:InvalidCell");
end

function testMatrixPredicate(testCase)
    % Matrix predicates should accept 2-D matrices and reject N-D arrays.
    testCase.verifyEqual(helper.chk(eye(2), "test:InvalidMatrix", "bad matrix", ...
        "numeric", "real", "finite", "matrix", "nonempty"), eye(2));
    testCase.verifyError(@() helper.chk(ones(1, 1, 2), "test:InvalidMatrix", ...
        "bad matrix", "matrix"), "test:InvalidMatrix");
end

function testUnknownPredicateFailsAsValidatorBug(testCase)
    % Unknown predicate tags indicate a helper bug, not caller bad input.
    testCase.verifyError(@() helper.chk(1, "test:InvalidValue", "bad value", ...
        "not-a-predicate"), "helper:InvalidValidatorCall");
end
