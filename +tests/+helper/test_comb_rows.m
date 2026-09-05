function tests = test_comb_rows
    % Public helper.comb_rows behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_column_vectors_and_singleton_middle_axis(testCase)
    % Input vector orientation cannot change the last-axis-fastest order.
    testCase.verifyEqual(helper.combRows({[2; 5], -7, [11; 13]}), ...
        [2 -7 11; 2 -7 13; 5 -7 11; 5 -7 13]);
end

function test_empty_axis_and_duplicate_values(testCase)
    % Empty products have no rows; repeated input labels are not deduplicated.
    testCase.verifyEqual(helper.combRows({[1 2], [], 7}), zeros(0, 3));
    testCase.verifyEqual(helper.combRows({[2 2], [3 5]}), [2 3; 2 5; 2 3; 2 5]);
end

function test_asymmetric_cartesian_order(testCase)
    testCase.verifyEqual(helper.combRows({[2 7], [-3 5 11], 4}), ...
        [2 -3 4;2 5 4;2 11 4;7 -3 4;7 5 4;7 11 4]);
    testCase.verifyEqual(helper.combRows({9}), 9);
end
