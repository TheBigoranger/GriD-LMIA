function tests = test_norm_deg
    % Behavioral regressions for helper.norm_deg.
    tests = functiontests(localfunctions);
end

function test_later_invalid_entry_and_integer_class(testCase)
    % Check the complete vector and normalize valid integer-valued classes.
    testCase.verifyEqual(helper.normDeg(uint8([0 3 1]), 3, "fixture:degree"), [0 3 1]);
    for bad = {[0 2 -1], [0 2 Inf], [0 2 0.5]}
        testCase.verifyError(@() helper.normDeg(bad{1}, 3, "fixture:degree"), "fixture:degree");
    end
end

function test_scalars_expand_uniformly_vector_orientation_public(testCase)
    % Scalars expand uniformly and vector orientation is not public state.
    testCase.verifyEqual( ...
        helper.normDeg(2, 3, "test:InvalidDegree", "Degree"), ...
        [2 2 2]);
    testCase.verifyEqual( ...
        helper.normDeg([0; 2; 1], 3, ...
        "test:InvalidDegree", "Degree"), [0 2 1]);
    testCase.verifyEqual( ...
        helper.normDeg([3 1 0], 3, ...
        "test:InvalidDegree", "Degree"), [3 1 0]);
    testCase.verifyEqual(helper.normDeg(1, 2, ...
        "test:InvalidDegree"), [1 1]);
end

function test_reject_shape_value_outside_scalar_or(testCase)
    % Reject every shape and value outside scalar-or-ell-vector degrees.
    bad = {[], [1 2], [1 2; 3 4], -1, 0.5, Inf, NaN, 1i, ...
        "one", true};
    for k = 1:numel(bad)
        testCase.verifyError(@() helper.normDeg( ...
            bad{k}, 3, "test:InvalidDegree", "Degree"), ...
            "test:InvalidDegree");
    end
end
