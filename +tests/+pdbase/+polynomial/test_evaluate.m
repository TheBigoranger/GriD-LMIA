function tests = test_evaluate
    % Behavioral regressions for pdbase.evaluate.
    tests = functiontests(localfunctions);
end

function test_fixed_rate_result_keeps_cell_container(testCase)
    % One fixed vertex is still rate-row storage; metadata-only bounds are not.
    A = pdbase({[0 2]}, [2 2], 1, ...
        {{[1 2; 3 4], [5 8; 11 16]}}, RateBounds=[3 3]);
    D = rhodiff(A);
    for point = [0 0.7 2]
        testCase.verifyEqual(evaluate(D, point), {[6 9; 12 18]});
        expected = (1 - point / 2) * [1 2; 3 4] + point / 2 * [5 8; 11 16];
        testCase.verifyEqual(evaluate(A, point), expected, AbsTol=1e-12);
    end
    testCase.verifyEqual(D.NumRateRows, 1);
    testCase.verifyEqual(A.NumRateRows, 0);
end

function test_discontinuous_tensor_internal_boundary_uses_right_cells(testCase)
    % Distinct constant pieces expose both internal-face and upper-bound ownership.
    vals = {{ {[1 2;3 5]}, {[7 11;13 17]} }, ...
        { {[19 23;29 31]}, {[37 41;43 47]} }};
    A = pdbase({[0 2 5],[-3 1 6]},[2 2],[0 0],vals);
    testCase.verifyEqual(A.evaluate([2 1]),[37 41;43 47]);
    testCase.verifyEqual(A.evaluate([2-eps(2) 1]),[7 11;13 17]);
    testCase.verifyEqual(A.evaluate([5 6]),[37 41;43 47]);
    testCase.verifyError(@() A.evaluate([2 6+eps(6)]),"pdbase:PointOutOfBounds");
end

function test_stored_coefficient_row_reconstruct_matrix_value(testCase)
    % One stored coefficient row should reconstruct one matrix value.
    obj = pdbase({[0 2]}, [1 1], 2, {{1, 3, 9}});

    val = obj.evaluate(1);

    testCase.verifyEqual(val, 4, AbsTol=1e-12);
end

function test_multiple_stored_rows_row_cell_array(testCase)
    % Multiple stored rows should remain a row cell array in storage order.
    vals = {{1, 3; 10, 14}};
    obj = pdbase({[0 2]}, [1 1], 1, vals, ...
        RateBounds=[-1 1]);

    rows = obj.evaluate(0.5);

    testCase.verifySize(rows, [1 2]);
    testCase.verifyEqual(rows{1}, 1.5, AbsTol=1e-12);
    testCase.verifyEqual(rows{2}, 11, AbsTol=1e-12);
end

function test_direct_pdbase_calls_own_malformed_out(testCase)
    % Direct pdbase calls should own malformed and out-of-domain errors.
    obj = pdbase({[0 1], [10 20]}, [1 1], 1);

    testCase.verifyError(@() obj.evaluate(0.5), "pdbase:InvalidPoint");
    testCase.verifyError(@() obj.evaluate([-0.1 12]), ...
        "pdbase:PointOutOfBounds");
end

function test_unequal_tensor_degrees_rectangular_rate_rows(testCase)
    % Explicit quadratic/cubic weights detect axis, entry and row permutations.
    for storage = 1:3
        c = cell(2, 12);
        for row = 1:2
            for k = 1:12
                c{row,k} = [k^2, -k, row; 3*k+row, k*row, -row^2];
                if storage == 2 || (storage == 3 && mod(k,2)==0)
                    c{row,k} = sparse(c{row,k});
                end
            end
        end
        A = pdbase({[0 2], [-1 4], [10 14]}, [2 3], [2 0 3], ...
            {{{c}}}, RateBounds=[-1 1; 0 0; 0 0]);
        for a = [0, eps, 0.27, 1-eps, 1]
            for b = [0, 0.63, 1]
                wa = [(1-a)^2, 2*a*(1-a), a^2];
                wb = [(1-b)^3, 3*b*(1-b)^2, 3*b^2*(1-b), b^3];
                actual = A.evaluate([2*a, 0, 10+4*b]);
                testCase.verifySize(actual, [1 2]);
                for row = 1:2
                    expected = zeros(2,3);
                    for i = 1:3
                        for j = 1:4
                            expected = expected + c{row,4*(i-1)+j}*wa(i)*wb(j);
                        end
                    end
                    testCase.verifyEqual(full(actual{row}), full(expected), AbsTol=1e-11);
                    testCase.verifyEqual(issparse(actual{row}), issparse(expected));
                end
            end
        end
    end
end

function test_single_coefficients_keep_original_arithmetic(testCase)
    c = {single([1 2; 3 4]), single([5 6; 7 8])};
    A = pdbase({[0 1]}, [2 2], 1, {c});
    actual = A.evaluate(0.25);
    testCase.verifyClass(actual, 'single');
    testCase.verifyEqual(actual, single([2 3; 4 5]));
end

function test_all_rows_at_endpoints_and_interior(testCase)
    for rates = [false true]
        A = tests.infrastructure.fixture("pdbase", rates);
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
