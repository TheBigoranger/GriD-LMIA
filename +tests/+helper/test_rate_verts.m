function tests = test_rate_verts
    % Public helper.rate_verts behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_last_fixed_axis_does_not_permute_vertices(testCase)
    % Fixed interior and trailing axes retain their physical parameter slots.
    actual = helper.rateVerts([-2 3; 7 7; -5 11; -13 -13]);
    testCase.verifyEqual(actual, [-2 7 -5 -13; -2 7 11 -13; ...
        3 7 -5 -13; 3 7 11 -13]);
end

function test_zero_and_nonzero_fixed_boxes_keep_one_row(testCase)
    % Zero-width boxes are single vertices, even when every rate is zero.
    testCase.verifyEqual(helper.rateVerts(zeros(3,2)), [0 0 0]);
    testCase.verifyEqual(helper.rateVerts([-2 -2; 0 0; 9 9]), [-2 0 9]);
    testCase.verifyEqual(helper.rateVerts([-eps eps]), [-eps; eps]);
end

function test_fixed_and_varying_directions(testCase)
    testCase.verifyEqual(helper.rateVerts([2 2;-3 5;7 11]), ...
        [2 -3 7;2 -3 11;2 5 7;2 5 11]);
    testCase.verifyEqual(helper.rateVerts([2 2;7 7]), [2 7]);
    testCase.verifyEqual(helper.rateVerts([]), zeros(0,0));
end
