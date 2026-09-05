function tests = test_chk
    % Behavioral regressions for helper.chk.
    tests = functiontests(localfunctions);
end

function test_later_matrix_entry_and_last_rate_bound_fail(testCase)
    % Later invalid entries must retain the caller diagnostic in chained checks.
    testCase.verifyError(@() helper.chk([1 2;3 NaN], "fixture:value", ...
        "matrix", "numeric", "real", "finite"), "fixture:value");
    testCase.verifyError(@() helper.chk([-2 3;5 4], "fixture:bounds", ...
        "bounds", "numeric", "finite", "rowbounds"), "fixture:bounds");
    testCase.verifyEqual(helper.chk([-2 3;5 5], "fixture:bounds", ...
        "bounds", "numeric", "finite", "rowbounds"), [-2 3;5 5]);
end

function test_valid_numeric_predicate_chains_return_original(testCase)
    % Valid numeric predicate chains should return the original value.
    val = helper.chk([1 2], "test:InvalidValue", "bad value", ...
        "numeric", "real", "finite", "integer", "positive", "Size", [1, 2]);

    testCase.verifyEqual(val, [1 2]);
end

function test_cell_validation_failures_preserve_caller_id(testCase)
    % Cell validation failures preserve the caller ID and standard label text.
    err = catchErr(@() helper.chk({1, 2}, "test:InvalidCell", ...
        "bad cell", "cell", "Numel", 3));

    testCase.verifyEqual(string(err.identifier), "test:InvalidCell");
    testCase.verifyEqual(string(err.message), ...
        "bad cell must contain 3 elements.");
end

function test_matrix_predicates_accept_2_d_matrices(testCase)
    % Matrix predicates should accept 2-D matrices and reject N-D arrays.
    testCase.verifyEqual(helper.chk(eye(2), "test:InvalidMatrix", "bad matrix", ...
        "numeric", "real", "finite", "matrix", "nonempty"), eye(2));
    testCase.verifyError(@() helper.chk(ones(1, 1, 2), "test:InvalidMatrix", ...
        "bad matrix", "matrix"), "test:InvalidMatrix");
end

function test_unknown_predicate_tags_indicate_helper_bug(testCase)
    % Unknown predicate tags indicate a helper bug, not caller bad input.
    testCase.verifyError(@() helper.chk(1, "test:InvalidValue", "bad value", ...
        "not-a-predicate"), "helper:InvalidValidatorCall");
end

function test_predicate_order_owns_first_standardized_failure(testCase)
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

function test_range_count_options_caller_errors_malformed(testCase)
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
