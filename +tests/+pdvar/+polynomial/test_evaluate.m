function tests = test_evaluate
    % Behavioral regressions for pdvar.evaluate.
    tests = functiontests(localfunctions);
end

function test_fixed_tensor_rectangular_values_have_one_active_row(testCase)
    % Evaluate tensor Bernstein weights directly, including a zero-degree axis.
    P = pdvar(2,3,{[0 2 5],[-3 1 6]},'full',Degree=[0 2]);
    D = rhodiff(P,[3 3;-2 -2]);
    xnodes = [0 2 5]; ynodes = [-3 1 6];
    for i = 1:2
        for j = 1:2
            c = D.coeffs([i j]);
            for alpha = [.2 .65 1]
                if j==1 && alpha==1, continue; end
                point = [(xnodes(i)+xnodes(i+1))/2, ...
                    ynodes(j)+alpha*(ynodes(j+1)-ynodes(j))];
                expected = (1-alpha)^2*c{1}+2*alpha*(1-alpha)*c{2}+alpha^2*c{3};
                actual = evaluate(D,point);
                testCase.verifyClass(actual,'cell');
                if ~iscell(actual), return; end
                testCase.verifySize(actual,[1 1]);
                tests.infrastructure.verify_expr(testCase,actual{1},expected);
            end
        end
    end
end

function setupOnce(~)
    % Keep assigned values from other tests out of symbolic evaluation checks.
    yalmip("clear");
end

function test_evaluation_assembles_affine_expression_never_calls(testCase)
    % Evaluation assembles one affine expression and never calls value.
    P = pdvar(2, {[0 2]}, "full", Degree=2);
    coeffs = P.coeffs(1);
    before = P.evaluate(1);
    expected = 0.25 * coeffs{1} + 0.5 * coeffs{2} + 0.25 * coeffs{3};

    verifyAffineEqual(testCase, before, expected);
    assignCoeffs(coeffs, {
        [1 2; 3 4], ...
        [5 6; 7 8], ...
        [9 10; 11 12]
    });
    after = P.evaluate(1);

    testCase.verifyClass(before, "sdpvar");
    testCase.verifyClass(after, "sdpvar");
    verifyAffineEqual(testCase, after, expected);
    testCase.verifyEqual(value(after), [5 6; 7 8], AbsTol=1e-12);
end

function test_tensor_weights_follow_combrows_order_metadata(testCase)
    % Tensor weights follow combRows order; metadata alone adds no output rows.
    P = pdvar(1, {[0 1], [10 14]}, Degree=[1 1], ...
        RateBounds=[-1 2; -3 5]);
    coeffs = P.coeffs([1 1]);
    assignCoeffs(coeffs, {1, 3, 5, 7});

    expr = P.evaluate([0.25 11]);

    testCase.verifyFalse(iscell(expr));
    testCase.verifyClass(expr, "sdpvar");
    testCase.verifyEqual(value(expr), 2.5, AbsTol=1e-12);
end

function test_each_stored_rate_row_becomes_matrix(testCase)
    % Each stored rate row becomes one matrix-valued affine expression.
    P = pdvar(1, {[0 2]}, Degree=2);
    coeffs = P.coeffs(1);
    D = rhodiff(P, [-2 3]);

    rows = D.evaluate(1);

    testCase.verifySize(rows, [1 2]);
    testCase.verifyClass(rows{1}, "sdpvar");
    testCase.verifyClass(rows{2}, "sdpvar");
    assignCoeffs(coeffs, {1, 4, 9});
    testCase.verifyEqual(value(rows{1}), -8, AbsTol=1e-12);
    testCase.verifyEqual(value(rows{2}), 12, AbsTol=1e-12);
end

function test_four_rate_vertices_package_wide_lower(testCase)
    % Four rate vertices retain the package-wide lower/upper Cartesian order.
    grid = {[0 2], [10 14]};
    rb = [-1 2; -3 5];
    P = pdvar(1, grid, Degree=[2 2]);
    coeffs = P.coeffs([1 1]);
    lbls = helper.combRows({0:2, 0:2});
    vals = arrayfun(@(k) 5 + 2 * lbls(k, 1) + 3 * lbls(k, 2), ...
        1:size(lbls, 1), UniformOutput=false);
    assignCoeffs(coeffs, vals);
    D = rhodiff(P, rb);

    rows = D.evaluate([0.4 12]);

    testCase.verifySize(rows, [1 4]);
    expected = [-6.5, 5.5, -0.5, 11.5];
    for k = 1:4
        testCase.verifyClass(rows{k}, "sdpvar");
        testCase.verifyEqual(value(rows{k}), expected(k), AbsTol=1e-12);
    end
end

function test_discontinuous_derivative_makes_boundary_owner(testCase)
    % A discontinuous derivative makes the shared-boundary owner observable.
    P = pdvar(1, {[0 1 2]}, Degree=2);
    left = P.coeffs(1);
    right = P.coeffs(2);
    assignCoeffs(left, {0, 0, 0});
    assign(right{2}, 1);
    assign(right{3}, 3);
    D = rhodiff(P, [-1 1]);

    rows = D.evaluate(1);

    testCase.verifyEqual(value(rows{1}), -2, AbsTol=1e-12);
    testCase.verifyEqual(value(rows{2}), 2, AbsTol=1e-12);
end

function test_public_validation_distinguishes_malformed_points(testCase)
    % Public validation distinguishes malformed points from domain violations.
    P = pdvar(1, {[0 1], [10 20]});

    bad = {0.5, [0.5 12 7], [0.5 NaN], "point"};
    for k = 1:numel(bad)
        testCase.verifyError(@() P.evaluate(bad{k}), "pdvar:InvalidPoint");
    end
    testCase.verifyError(@() P.evaluate([-0.1 12]), ...
        "pdvar:PointOutOfBounds");
end

function assignCoeffs(coeffs, vals)
    % Assign deterministic values without changing the stored affine formulas.
    for k = 1:numel(coeffs)
        assign(coeffs{k}, vals{k});
    end
end

function verifyAffineEqual(testCase, actual, expected)
    % Compare YALMIP affine bases instead of their possibly unassigned values.
    diff = actual - expected;
    base = full(getbase(diff));
    testCase.verifyEqual(base, zeros(size(base)), AbsTol=1e-12);
end
function test_all_rows_at_endpoints_and_interior(testCase)
    for rates = [false true]
        A = tests.infrastructure.fixture("pdvar", rates);
        nodes = [0 2 5];
        for cellIndex = 1:2
            c = A.coeffs(cellIndex);
            for alpha = [0 0.3 1]
                % The right cell owns an internal boundary; skip the left limit.
                if cellIndex == 1 && alpha == 1, continue; end
                point = nodes(cellIndex) + alpha*(nodes(cellIndex+1)-nodes(cellIndex));
                expected = cell(1,size(c,1));
                for row = 1:size(c,1)
                    expected{row} = 0*c{row,1};
                    for k = 0:A.Degree
                        expected{row} = expected{row} + nchoosek(A.Degree,k)* ...
                            alpha^k*(1-alpha)^(A.Degree-k)*c{row,k+1};
                    end
                end
                if ~rates, expected=expected{1}; end
                tests.infrastructure.verify_expr(testCase, evaluate(A,point), expected);
            end
        end
    end
end
