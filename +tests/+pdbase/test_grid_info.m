function tests = test_grid_info
    %TEST_GRID_INFO GridInfo field contract and tensor point order.
    tests = functiontests(localfunctions);
end

function testFields(testCase)
    % GridInfo should expose stable primitive grid metadata only.
    obj = pdbase({[0 1], [10 20 30]}, [1 1], 1);

    % GridInfo should expose only primitive facts; derived counts stay computed.
    testCase.verifyEqual(fieldnames(obj.GridInfo), ...
        {'Vectors'; 'Points'; 'Bounds'; 'NumNodes'});
    testCase.verifyEqual(obj.GridInfo.Vectors, {[0 1], [10 20 30]});
    testCase.verifyEqual(obj.GridInfo.Bounds, [0 1; 10 30]);
    testCase.verifyEqual(obj.GridInfo.NumNodes, [2 3]);
end

function testPointOrder(testCase)
    % Tensor grid points should follow MATLAB row-order enumeration.
    obj = pdbase({[0 1], [10 20 30]}, [1 1], 0);

    expected = [
        0    10
        0    20
        0    30
        1    10
        1    20
        1    30
        ];
    testCase.verifyEqual(obj.GridInfo.Points, expected);
end
