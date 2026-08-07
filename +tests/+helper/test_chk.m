function tests = test_chk
    %TEST_CHK Shared sanity predicate helper.
    tests = functiontests(localfunctions);
end

function testValNumPreRetInp(testCase)
    % Valid numeric predicate chains should return the original value.
    val = helper.chk([1 2], "test:InvalidValue", "bad value", ...
        "numeric", "real", "finite", "integer", "positive", "Size", [1, 2]);

    testCase.verifyEqual(val, [1 2]);
end

function testCelShaPreUseCal(testCase)
    % Cell validation failures preserve the caller ID and standard label text.
    err = catchErr(@() helper.chk({1, 2}, "test:InvalidCell", ...
        "bad cell", "cell", "Numel", 3));

    testCase.verifyEqual(string(err.identifier), "test:InvalidCell");
    testCase.verifyEqual(string(err.message), ...
        "bad cell must contain 3 elements.");
end

function testMatrixPredicate(testCase)
    % Matrix predicates should accept 2-D matrices and reject N-D arrays.
    testCase.verifyEqual(helper.chk(eye(2), "test:InvalidMatrix", "bad matrix", ...
        "numeric", "real", "finite", "matrix", "nonempty"), eye(2));
    testCase.verifyError(@() helper.chk(ones(1, 1, 2), "test:InvalidMatrix", ...
        "bad matrix", "matrix"), "test:InvalidMatrix");
end

function testUnkPreFaiAsVal(testCase)
    % Unknown predicate tags indicate a helper bug, not caller bad input.
    testCase.verifyError(@() helper.chk(1, "test:InvalidValue", "bad value", ...
        "not-a-predicate"), "helper:InvalidValidatorCall");
end

function testMsgAndPrecedence(testCase)
    % Predicate order owns the first standardized failure and its message.
    err = catchErr(@() helper.chk("bad", "test:InvalidValue", ...
        "input value", "numeric", "finite", "vector"));

    testCase.verifyEqual(string(err.identifier), "test:InvalidValue");
    testCase.verifyEqual(string(err.message), ...
        "input value must be numeric.");

    err = catchErr(@() helper.chk([1 2], "test:InvalidValue", ...
        "input value", "scalar", "Numel", 3));
    testCase.verifyEqual(string(err.identifier), "test:InvalidValue");
    testCase.verifyEqual(string(err.message), ...
        "input value must be scalar.");
end

function testBouOptAndCalErr(testCase)
    % Range and count options retain caller errors; malformed calls are helper bugs.
    testCase.verifyError(@() helper.chk(-1, "test:InvalidValue", ...
        "input value", "nonnegative"), "test:InvalidValue");
    testCase.verifyEqual(helper.chk(2, "test:InvalidValue", ...
        "input value", "Min", 1, "Max", 3), 2);
    testCase.verifyError(@() helper.chk({1}, "test:InvalidValue", ...
        "input value", "MinNumel", 2), "test:InvalidValue");
    testCase.verifyError(@() helper.chk(0, "test:InvalidValue", ...
        "input value", "Min", 1), "test:InvalidValue");
    testCase.verifyError(@() helper.chk(4, "test:InvalidValue", ...
        "input value", "Max", 3), "test:InvalidValue");
    testCase.verifyError(@() helper.chk(1, "test:InvalidValue", ...
        "input value", "Min"), "helper:InvalidValidatorCall");
end

function err = catchErr(fcn)
    % Return the thrown exception so tests can lock both ID and message.
    try
        fcn();
        error("tests:ExpectedError", "The tested call did not fail.");
    catch err
    end
end
