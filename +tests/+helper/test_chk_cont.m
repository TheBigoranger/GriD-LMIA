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

function test_directionwise_orders_use_physical_widths(testCase)
    % The right-cell forward differences must be scaled by its own width.
    grid = {[0 1 3]};
    c2 = {{0, 1, 3, 6}, {6, 12, 22, 40}};

    [tf, continuity] = helper.chkCont(c2, 2, 3, grid);
    testCase.verifyFalse(tf);
    testCase.verifyEqual(continuity, 2);
    testCase.verifyTrue(helper.chkCont(c2, 2, 3, grid, 2));
    testCase.verifyFalse(helper.chkCont(c2, 2, 3, grid, 3));

    c1 = c2;
    c1{2}{3} = 21;
    [~, continuity] = helper.chkCont(c1, 2, 3, grid);
    testCase.verifyEqual(continuity, 1);

    c0 = c1;
    c0{2}{2} = 11;
    [~, continuity] = helper.chkCont(c0, 2, 3, grid);
    testCase.verifyEqual(continuity, 0);

    broken = c0;
    broken{2}{1} = 7;
    [tf, continuity] = helper.chkCont(broken, 2, 3, grid);
    testCase.verifyFalse(tf);
    testCase.verifyEqual(continuity, -1);
end

function test_complete_polynomial_classifies_as_infinite(testCase)
    % Cubic Bernstein controls for x^2 agree through every representable order.
    grid = {[0 1 3]};
    values = {{0, 0, 1/3, 1}, {1, 7/3, 5, 9}};

    [tf, continuity] = helper.chkCont(values, 2, 3, grid);

    testCase.verifyTrue(tf);
    testCase.verifyEqual(continuity, Inf);
end

function test_late_interface_matrix_entry_and_rate_row_classification(testCase)
    % A C1 defect in the last entry of the last rate row must not be skipped.
    z = zeros(2);
    eye2 = eye(2);
    two = 2 * eye2;
    three = 3 * eye2;
    four = 4 * eye2;
    five = 5 * eye2;
    six = 6 * eye2;
    values = {
        {z, eye2, two; 10+z, 10+eye2, 10+two}, ...
        {two, three, four; 10+two, 10+three, 10+four}, ...
        {four, five, six; 10+four, 10+five, 10+six}
        };
    values{3}{2, 2}(2, 2) = values{3}{2, 2}(2, 2) + 1;

    [tf, continuity] = helper.chkCont(values, 3, 2, {[0 1 2 3]});

    testCase.verifyFalse(tf);
    testCase.verifyEqual(continuity, 0);
end

function test_affine_symbolic_derivatives_compare_exact_bases(testCase)
    % Matching symbolic differences compare their complete affine bases exactly.
    x = sdpvar(1);
    y = sdpvar(1);
    values = {{x, y}, {y, 3*y - 2*x}};

    [tf, continuity] = helper.chkCont(values, 2, 1, {[0 1 3]});
    testCase.verifyTrue(tf);
    testCase.verifyEqual(continuity, Inf);

    values{2}{2} = values{2}{2} + sdpvar(1);
    [tf, continuity] = helper.chkCont(values, 2, 1, {[0 1 3]});
    testCase.verifyFalse(tf);
    testCase.verifyEqual(continuity, 0);
end

function test_invalid_direction_metadata_is_rejected(testCase)
    values = {{0, 1}, {1, 2}};
    testCase.verifyError(@() helper.chkCont(values, [2 1], 1), ...
        "helper:InvalidContinuityInput");
    testCase.verifyError(@() helper.chkCont(values, 2, 1, ...
        {[0 1 2], [0 1]}), "helper:InvalidContinuityInput");
    testCase.verifyError(@() helper.chkCont(values, 2, 1, ...
        {[0 1 2]}, [0 1]), "helper:InvalidContinuityInput");
end

function test_nonunit_derivative_threshold_and_interior_face_entry(testCase)
    % A last-entry perturbation crosses the existing derivative tolerance,
    % after conversion from normalized controls to physical derivatives.
    values = {{zeros(2),eye(2)}, {eye(2),3*eye(2)}};
    within = values;
    within{2}{2}(2,2) = within{2}{2}(2,2)+1e-9;
    outside = values;
    outside{2}{2}(2,2) = outside{2}{2}(2,2)+1e-6;
    testCase.verifyTrue(helper.chkCont(within,2,1,{[-4 -2 2]},1));
    testCase.verifyFalse(helper.chkCont(outside,2,1,{[-4 -2 2]},1));

    % A tangential interior coefficient is neither a face corner nor a node.
    face = {{zeros(2),zeros(2),eye(2),eye(2),2*eye(2),2*eye(2)}, ...
        {zeros(2),zeros(2),eye(2),eye(2),2*eye(2),2*eye(2)}};
    nested = {face};
    testCase.verifyTrue(helper.chkCont(nested,[1 2],[2 1]));
    nested{1}{2}{3}(2,2) = 100;
    testCase.verifyFalse(helper.chkCont(nested,[1 2],[2 1]));
end
