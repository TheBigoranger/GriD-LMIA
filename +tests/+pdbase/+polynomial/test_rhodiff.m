function tests = test_rhodiff
    % Behavioral regressions for pdbase.rhodiff.
    tests = functiontests(localfunctions);
end

function test_tensor_zero_axis_nonuniform_widths_and_fixed_rates(testCase)
    % Differentiate the explicit y-quadratic controls and elevate the linear result.
    grid = {[0 2 5], [-3 1 6]}; vals = cell(1,2);
    for i=1:2
        vals{i}=cell(1,2);
        for j=1:2
            vals{i}{j} = {[i j;2*i -j], [3*i -2*j; i j], [7*i 5*j;-i 4*j]};
        end
    end
    for rates = {[-2 5], [-2 -2]}
        rb = [3 3; rates{1}];
        A = pdbase(grid,[2 2],[0 2],vals,RateBounds=rb);
        D = rhodiff(A); saved = A.LocalValues;
        verts = unique(rates{1},'stable');
        for i=1:2
            for j=1:2
                c=vals{i}{j}; h=grid{2}(j+1)-grid{2}(j);
                lo=2/h*(c{2}-c{1}); hi=2/h*(c{3}-c{2});
                expected=cell(numel(verts),3);
                for r=1:numel(verts)
                    expected(r,:)={verts(r)*lo, verts(r)*(lo+hi)/2, verts(r)*hi};
                end
                tests.infrastructure.verify_expr(testCase,D.coeffs([i j]),expected);
            end
        end
        testCase.verifyEqual(A.LocalValues,saved);
        testCase.verifyEqual(D.Degree,[0 2]);
        testCase.verifyEqual(D.NumRateRows,numel(verts));
        testCase.verifyFalse(D.IsContinuous);
        testCase.verifyError(@() rhodiff(D),"pdbase:InvalidDiff");
    end
end

function test_parent_implementation_dynamic_class_row_order(testCase)
    % The parent implementation should retain the dynamic class and row order.
    A = pdbase({[0 2]}, [1 1], 1, {{1, 5}}, ...
        RateBounds=[-2 3], IsContinuous=true);

    D = rhodiff(A);

    testCase.verifyClass(D, "pdbase");
    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyEqual(D.coeffs(1), {-4; 6});
    veriDerSta(testCase, D, [-2 3]);
end

function test_linear_tensor_polynomial_has_constant_partial(testCase)
    % A linear tensor polynomial has one constant partial per parameter.
    grid = {[0 2], [10 14]};
    rb = [-1 2; -3 5];
    leaf = {30, 42, 34, 46};
    A = pdbase(grid, [1 1], 1, {{leaf}}, RateBounds=rb);

    D = rhodiff(A);

    expected = repmat(num2cell([-11; 13; -5; 19]), 1, 4);
    testCase.verifyEqual(D.Degree, [1 1]);
    testCase.verifyEqual(D.coeffs([1 1]), expected);
    veriDerSta(testCase, D, rb);
end

function test_degree_zero_input_still_produces_complete(testCase)
    % Degree-zero input still produces a complete zero rate-vertex table.
    A = pdbase({[0 1]}, [2 2], 0, {{eye(2)}});

    D = rhodiff(A, [-1 2]);

    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyEqual(D.coeffs(1), {zeros(2); zeros(2)});
    testCase.verifyFalse(D.ContainsDecision);
    veriDerSta(testCase, D, [-1 2]);
end

function test_fixed_scheduling_rate_vertex_two_duplicate(testCase)
    % A fixed scheduling rate is one vertex, not two duplicate endpoints.
    A = pdbase({[0 2]}, [1 1], 1, {{1, 5}}, ...
        RateBounds=[3 3], IsContinuous=true);

    D = rhodiff(A);

    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyEqual(D.coeffs(1), {6});
    veriDerSta(testCase, D, [3 3]);
end

function test_each_fixed_tensor_direction_removes_duplicate(testCase)
    % Each fixed tensor direction removes one duplicate Cartesian endpoint.
    grid = {[0 2], [10 14]};
    rb = [1 1; -3 5];
    A = pdbase(grid, [1 1], [1 1], {{ {30, 42, 34, 46} }}, ...
        RateBounds=rb);

    D = rhodiff(A);

    expected = repmat(num2cell([-7; 17]), 1, 4);
    testCase.verifyEqual(D.coeffs([1 1]), expected);
    testCase.verifyEqual(D.NumRateRows, 2);
    veriDerSta(testCase, D, rb);
end

function test_missing_malformed_mismatched_repeated_derivative(testCase)
    % Missing, malformed, mismatched, and repeated derivative requests fail.
    ordinary = pdbase({[0 1]}, [1 1], 1, {{1, 2}});
    stored = pdbase({[0 1]}, [1 1], 1, {{1, 2}}, ...
        RateBounds=[-1 1]);
    D = rhodiff(stored);

    testCase.verifyError(@() rhodiff(ordinary), ...
        "pdbase:MissingRateBounds");
    testCase.verifyError(@() rhodiff(ordinary, [0 1; -1 1]), ...
        "pdbase:InvalidRateBounds");
    testCase.verifyError(@() rhodiff(stored, [0 1]), ...
        "pdbase:RateBoundsMismatch");
    testCase.verifyError(@() rhodiff(D), "pdbase:InvalidDiff");
end

function veriDerSta(testCase, D, rb)
    % Every inherited derivative is rate-dependent and cellwise discontinuous.
    testCase.verifyFalse(D.IsContinuous);
    testCase.verifyEqual(D.RateBounds, rb);
    testCase.verifyEqual(D.SourceSummary, "derivative");
end
function test_unequal_cell_widths_and_rate_signs(testCase)
    A = tests.infrastructure.fixture("pdbase", false);
    D = rhodiff(A);
    widths = [2 3];
    rates = [-2 3];
    for cellIndex = 1:2
        input = A.coeffs(cellIndex);
        expected = cell(2,2);
        for row = 1:2
            for k = 1:2
                expected{row,k} = rates(row)*2/widths(cellIndex)*(input{k+1}-input{k});
            end
        end
        tests.infrastructure.verify_expr(testCase, D.coeffs(cellIndex), expected);
    end
    testCase.verifyEqual(D.Degree, 1);
    testCase.verifyEqual(D.NumRateRows, 2);
    fixedSource = tests.infrastructure.fixture("pdbase", false, [4 4]);
    input = fixedSource.coeffs(2);
    fixed = rhodiff(fixedSource);
    testCase.verifyEqual(fixed.NumRateRows, 1);
    tests.infrastructure.verify_expr(testCase, fixed.coeffs(2), ...
        {8/3*(input{2}-input{1}), 8/3*(input{3}-input{2})});
end
