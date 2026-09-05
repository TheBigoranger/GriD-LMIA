function tests = test_cell_get
    % Public helper.cell_get behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_three_axes_keep_rate_table_shape(testCase)
    % A selected leaf is returned intact, without flattening its row table.
    table = {[2 -3], [5 7]; [11 13], [-17 19]};
    values = {{{{0}}, {table}}};
    testCase.verifyEqual(helper.cellGet(values, [1 2 1]), table);
end

function test_root_and_partial_path_return_subtrees(testCase)
    % An empty path is the identity; partial traversal retains nested cells.
    values = {{1, {2, 3}}, {4, {5, 6}}};
    testCase.verifyEqual(helper.cellGet(values, []), values);
    testCase.verifyEqual(helper.cellGet(values, 2), {4, {5, 6}});
end

function test_nested_subscripts_preserve_payload(testCase)
    values = {{[2 7], [11 13]}, {[17 19], [23 29]}};
    testCase.verifyEqual(helper.cellGet(values,[2 1]), [17 19]);
    testCase.verifyEqual(helper.cellGet(values,[1 2]), [11 13]);
end
