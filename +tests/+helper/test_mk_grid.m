function tests = test_mk_grid
    % Behavioral regressions for helper.mk_grid.
    tests = functiontests(localfunctions);
end

function test_later_axis_invalid_and_column_normalization(testCase)
    % Validate every axis while normalizing column-vector orientation.
    actual = helper.mkGrid({[-3; 1; 8], [2; 5]}, "fixture");
    testCase.verifyEqual(actual.Vectors, {[-3 1 8], [2 5]});
    testCase.verifyEqual(actual.Points, [-3 2;-3 5;1 2;1 5;8 2;8 5]);
    for bad = {[1 1], [0 NaN], [3 2], [1 1i]}
        testCase.verifyError(@() helper.mkGrid({[0 1], bad{1}}, "fixture"), ...
            "fixture:InvalidGridVector");
    end
end

function test_standalone_grid_helper_defaults_pdbase_owned(testCase)
    % The standalone grid helper defaults to pdbase-owned diagnostics.
    info = helper.mkGrid({[0 1], [10 20]});

    testCase.verifyEqual(info.NumNodes, [2 2]);
    testCase.verifyError(@() helper.mkGrid({[0 0]}), ...
        "pdbase:InvalidGridVector");
end

function test_complete_grid_metadata(testCase)
    actual = helper.mkGrid({[2 7 11],[-3 5]});
    testCase.verifyEqual(actual.Vectors, {[2 7 11],[-3 5]});
    testCase.verifyEqual(actual.Bounds, [2 11;-3 5]);
    testCase.verifyEqual(actual.NumNodes, [3 2]);
    testCase.verifyEqual(actual.Points, [2 -3;2 5;7 -3;7 5;11 -3;11 5]);
    testCase.verifyError(@() helper.mkGrid({[2 2]},'fixture'), 'fixture:InvalidGridVector');
end
