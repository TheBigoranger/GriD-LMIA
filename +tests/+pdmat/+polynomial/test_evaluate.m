function tests = test_evaluate
    % Behavioral regressions for pdmat.evaluate.
    tests = functiontests(localfunctions);
end

function test_fixed_rate_evaluation_preserves_single_row_cell_output(testCase)
    % One active rate row remains a table, unlike ordinary rate metadata.
    f = @(x,y) [x^2+y, x*y; y^2, 3*x-y];
    A = pdmat({[0 .5 2], [-1 0 3]}, f, ...
        Degree=[2 2], RateBounds=[2 2; -3 -3]);
    D = rhodiff(A);
    testCase.verifyEqual(D.NumRateRows, 1);
    for x = [0 .25 .5 1.25 2]
        for y = [-1 -.5 0 1.5 3]
            expected = [4*x-3, 2*y-3*x; -6*y, 9];
            testCase.verifyEqual(D.evaluate([x y]), {expected}, AbsTol=1e-10);
            testCase.verifyEqual(A.evaluate([x y]), f(x,y), AbsTol=1e-10);
        end
    end
end
function test_tensor_derivative_values_match_physical_analytic_oracle(testCase)
    % An analytic derivative checks unequal widths and every active rate row.
    f = @(x,y) [x^2+y, x*y; y^2, 3*x-y];
    A = pdmat({[0 .5 2], [-1 0 3]}, f, ...
        Degree=[2 2], RateBounds=[2 2; -3 5]);
    D = rhodiff(A);
    for x = [0 .25 .5 1.25 2]
        for y = [-1 -.5 0 1.5 3]
            values = D.evaluate([x y]);
            for row = 1:2
                rate = [-3 5];
                expected = [4*x+rate(row), 2*y+x*rate(row); ...
                    2*y*rate(row), 6-rate(row)];
                testCase.verifyEqual(values{row}, expected, AbsTol=1e-10);
            end
        end
    end
end

function test_scalar_coefficient_backed_data_evaluate_by(testCase)
    % Scalar coefficient-backed data should evaluate by Bernstein interpolation.
    A = pdmat({[0 1]}, {2, 4}, Degree=1);

    testCase.verifyEqual(evaluate(A, 0.25), 2.5, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(0.75), 3.5, AbsTol=1e-12);
end

function test_tensor_coefficient_backed_data_interpolate_across(testCase)
    % Tensor coefficient-backed data should interpolate across both dimensions.
    A = pdmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=[1 1]);

    val = A.evaluate([0.25, 12.5]);

    testCase.verifyEqual(val, 2.5, AbsTol=1e-12);
end

function test_3_d_degree_2_data_evaluate(testCase)
    % 3-D degree-2 data should evaluate with tensor Bernstein weights.
    data = cell(3, 3, 3);
    for i = 0:2
        for j = 0:2
            for k = 0:2
                data{i + 1, j + 1, k + 1} = i + 10 * j + 100 * k;
            end
        end
    end
    A = pdmat({[0 1], [0 1], [0 1]}, data, Degree=[2 2 2]);

    val = A.evaluate([0.25, 0.5, 0.75]);

    testCase.verifyEqual(val, 160.5, AbsTol=1e-12);
end

function test_these_controls_represent_rho_2_independently(testCase)
    % These controls represent rho^2 independently on two unequal cells.
    A = pdmat({[-2 0.5 4]}, {4, -1, 0.25, 2, 16}, Degree=2);

    testCase.verifyEqual(A.evaluate(-2), 4, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(-0.75), 0.75^2, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(0.5), 0.25, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(2.25), 2.25^2, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(4), 16, AbsTol=1e-12);
end

function test_function_backed_pdmat_evaluate_retained_exact(testCase)
    % Function-backed pdmat should evaluate through the retained exact handle.
    A = pdmat({[0 pi]}, @(rho) sin(rho));

    testCase.verifyEqual(A.evaluate(pi / 2), 1, AbsTol=1e-12);
end

function test_function_bernstein_objects_evaluate_original_handle(testCase)
    % Function-Bernstein objects should evaluate through the original handle.
    A = pdmat({[0 1]}, @(rho) rho.^2, Degree=2);

    testCase.verifyEqual(A.evaluate(0.5), 0.25, AbsTol=1e-12);
end

function test_exact_handles_still_obey_grid_bounds(testCase)
    % Exact handles still obey grid bounds and the stored matrix contract.
    bounded = pdmat({[0 1]}, @(rho) rho);
    throws = pdmat({[0 1]}, @(rho) failAwaFroLowBou(rho));
    wrongSize = pdmat({[0 1]}, @(rho) chanSizAwaFroLowBou(rho));

    testCase.verifyError(@() bounded.evaluate(1.1), ...
        "pdmat:PointOutOfBounds");
    testCase.verifyError(@() throws.evaluate(0.5), ...
        "pdmat:InvalidFunctionValue");
    testCase.verifyError(@() wrongSize.evaluate(0.5), ...
        "pdmat:InvalidFunctionValue");
end

function test_evaluation_reject_out_bounds_wrong_dimensional(testCase)
    % Evaluation should reject out-of-bounds and wrong-dimensional points.
    A = pdmat({[0 1]}, {2, 4}, Degree=1);

    testCase.verifyError(@() A.evaluate(-0.1), "pdmat:PointOutOfBounds");
    testCase.verifyError(@() A.evaluate([0.5 0.5]), "pdmat:InvalidPoint");
end

function test_distinct_face_values_make_deterministic_right(testCase)
    % Distinct face values make deterministic right-cell ownership observable.
    state = warning("query", "pdmat:DiscontinuousLocalValues");
    cleanup = onCleanup(@() warning(state.state, ...
        "pdmat:DiscontinuousLocalValues")); %#ok<NASGU>
    warning("off", "pdmat:DiscontinuousLocalValues");
    A = pdmat({[0 1 2]}, {{1, 2}, {20, 3}}, Degree=1);

    testCase.verifyEqual(A.evaluate(0), 1, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(1), 20, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(2), 3, AbsTol=1e-12);
end

function out = failAwaFroLowBou(rho)
    if rho == 0
        out = 0;
        return
    end
    error("tests:ExpectedHandleFailure", "deliberate evaluation failure");
end

function out = chanSizAwaFroLowBou(rho)
    if rho == 0
        out = 0;
    else
        out = eye(2);
    end
end
function test_all_rows_at_endpoints_and_interior(testCase)
    for rates = [false true]
        A = tests.infrastructure.fixture("pdmat", rates);
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
