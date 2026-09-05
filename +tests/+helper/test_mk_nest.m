function tests = test_mk_nest
    % Public helper.mk_nest behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_singleton_middle_axis_preserves_all_subscripts(testCase)
    % Full physical subscripts reach each terminal leaf in three dimensions.
    actual = helper.mkNest([2 1 2], @(s) s);
    expected = {{{[1 1 1], [1 1 2]}}, {{[2 1 1], [2 1 2]}}};
    testCase.verifyEqual(actual, expected);
end

function test_cell_payload_is_not_flattened(testCase)
    % Leaf cells are payloads, not another physical recursion level.
    actual = helper.mkNest([1 2], @(s) {s, -s; 2*s, 3*s});
    testCase.verifyEqual(actual{1}{1}, {[1 1], [-1 -1]; [2 2], [3 3]});
    testCase.verifyEqual(actual{1}{2}, {[1 2], [-1 -2]; [2 4], [3 6]});
end

function test_all_leaves_receive_full_subscripts(testCase)
    actual = helper.mkNest([2 3], @(s) 10*s(1)+s(2));
    testCase.verifyEqual(actual, {{11,12,13},{21,22,23}});
    testCase.verifyEqual(helper.mkNest(1, @(s) s), {1});
end
