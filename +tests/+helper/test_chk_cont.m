function tests = test_chk_cont
    % Public helper.chk_cont behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_face_checks_every_row_and_corner(testCase)
    % Matching full faces must include the last coefficient of the last row.
    values = {{ {1,2,3,4;11,12,13,14}, {2,5,4,6;12,15,14,16} }, ...
        { {3,4,7,8;13,14,17,18}, {4,6,8,9;14,16,18,19} }};
    testCase.verifyTrue(helper.chkCont(values, [2 2], [1 1]));
    values{2}{2}{2,3} = 180;
    testCase.verifyFalse(helper.chkCont(values, [2 2], [1 1]));
end

function test_zero_degree_axis_still_requires_matching_faces(testCase)
    % A constant axis cannot hide jumps between neighboring physical cells.
    values = {{ {1,2,3} }, { {1,2,3} }};
    testCase.verifyTrue(helper.chkCont(values, [2 1], [0 2]));
    values{2}{1}{3} = 4;
    testCase.verifyFalse(helper.chkCont(values, [2 1], [0 2]));
end

function test_late_cell_row_and_numeric_threshold(testCase)
    values = {{1,2;10,20},{2,3;20,30},{3,4;30,40}};
    testCase.verifyTrue(helper.chkCont(values,3,1));
    values{3}{2,1}=30+1e-9;
    testCase.verifyTrue(helper.chkCont(values,3,1));
    values{3}{2,1}=30+1e-6;
    testCase.verifyFalse(helper.chkCont(values,3,1));
    P=sdpvar(1); Q=sdpvar(1);
    testCase.verifyTrue(helper.chkCont({{P,P},{P,Q}},2,1));
    testCase.verifyFalse(helper.chkCont({{P,P},{Q,Q}},2,1));
end
