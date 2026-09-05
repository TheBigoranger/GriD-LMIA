function tests = test_fit_vals
    % Public helper.fit_vals behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_zero_degree_axis_and_rectangular_tensor_polynomial(testCase)
    % Analytic quadratic controls lock physical widths and zero-degree axes.
    info = struct('Vectors', {{[-4 -1 2], [1 3 8]}}, 'NumNodes', [3 3]);
    f = @(r) [r(2)^2, 2*r(2)+1, -3; 7, -r(2)^2, r(2)];
    [actual, labels] = helper.fitVals(info, [0 2], [2 3], f, "fixture");
    testCase.verifyEqual(labels, [0 0; 0 1; 0 2]);
    nodes = [1 3 8];
    for i = 1:2
        for j = 1:2
            a = nodes(j); b = nodes(j+1);
            expected = {f([0 a]), [a*b, a+b+1, -3; 7, -a*b, (a+b)/2], f([0 b])};
            tests.infrastructure.verify_expr(testCase, actual{i}{j}, expected);
        end
    end
end

function test_bilinear_tensor_corner_order(testCase)
    % Bilinear Bernstein controls equal ordered physical corner values.
    info = struct('Vectors', {{[2 5], [-3 7]}}, 'NumNodes', [2 2]);
    f = @(r) [r(1)*r(2), r(1)+2*r(2)];
    [actual, labels] = helper.fitVals(info, [1 1], [1 2], f, "fixture");
    testCase.verifyEqual(labels, [0 0; 0 1; 1 0; 1 1]);
    testCase.verifyEqual(actual, {{{[-6 -4], [14 16], [-15 -1], [35 19]}}});
end

function test_unequal_cell_matrix_polynomial(testCase)
    info = struct('Vectors', {{[0 2 5]}}, 'NumNodes', 3);
    [actual, labels] = helper.fitVals(info,2,[2 2], ...
        @(r) [r(1)^2 2*r(1)+3;-r(1) 7], 'fixture');
    testCase.verifyEqual(labels,[0;1;2]);
    expected = {{[0 3;0 7],[0 5;-1 7],[4 7;-2 7]}, ...
        {[4 7;-2 7],[10 10;-3.5 7],[25 13;-5 7]}};
    tests.infrastructure.verify_expr(testCase,actual,expected);
    testCase.verifyError(@() helper.fitVals(info,-1,[1 1],@(r) r,'fixture'), 'fixture:InvalidDegree');
end
