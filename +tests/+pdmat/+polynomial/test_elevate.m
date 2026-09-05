function tests = test_elevate
    % Behavioral regressions for pdmat.elevate.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    yalmip("clear");
end

function test_function_only_pdmat_placeholders_coefficient(testCase)
    % Function-only pdmat placeholders are not coefficient evidence.
    obj = pdmat({[0 1]}, @(rho) 1 + rho);

    testCase.verifyError(@() obj.elevate(1), ...
        "pdbase:MissingCoefficientEvidence");
end

function test_function_plus_degree_data_exact_evaluator(testCase)
    % Function-plus-degree data keeps its exact evaluator and metadata.
    A = pdmat({[-2 0.5 4]}, @(rho) rho.^2, Degree=2);

    B = A.elevate(2);

    testCase.verifyClass(B, "pdmat");
    testCase.verifyEqual(B.Degree, 4);
    testCase.verifyEqual(B.GridInfo, A.GridInfo);
    testCase.verifyEqual(B.MatrixSize, A.MatrixSize);
    testCase.verifyEqual(B.IsContinuous, A.IsContinuous);
    testCase.verifyEqual(B.SourceSummary, A.SourceSummary);
    testCase.verifyTrue(isequal(B.FunctionHandle, A.FunctionHandle));
    testCase.verifyEqual(B.evaluate(-0.75), A.evaluate(-0.75), AbsTol=1e-12);
    testCase.verifyEqual(B.evaluate(2.25), A.evaluate(2.25), AbsTol=1e-12);
    testCase.verifyEqual(A.Degree, 2);
end

function test_sparse_plan_internal_metadata_numeric_payloads(testCase)
    % A sparse plan is internal metadata; numeric payloads remain dense.
    source = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);

    elevated = source.elevate(3);
    coefficients = elevated.coeffs(1);

    testCase.verifyTrue(all(cellfun(@isnumeric, coefficients)));
    testCase.verifyFalse(any(cellfun(@issparse, coefficients)));
end

function test_fixed_tensor_direction_reduces_active_rows(testCase)
    % A fixed tensor direction reduces the active rows before elevation.
    [D, ~] = fixedTensorRateData();

    E = D.elevate([1 0]);

    testCase.verifyEqual(E.Degree, D.Degree + [1 0]);
    testCase.verifyEqual(E.NumRateRows, 2);
    testCase.verifyEqual(size(E.coeffs([1 1]), 1), 2);
    testCase.verifyEqual(E.RateBounds, D.RateBounds);
end

function [D, A] = fixedTensorRateData()
    % Build two stored rate rows from one fixed and one varying direction.
    grid = {[0 1], [10 12]};
    rb = [1 1; -3 5];
    source = pdmat(grid, @(rho, eta) rho + eta, ...
        Degree=[1 1], RateBounds=rb);
    D = rhodiff(source);
    A = pdmat(grid, @(rho, eta) 1 + rho, ...
        Degree=[1 0], RateBounds=rb);
end

function test_binomial_reference_all_rows(testCase)
    for rates = [false true]
        A = tests.infrastructure.fixture("pdmat", rates);
        saved = A.LocalValues;
        B = elevate(A, 2);
        for cellIndex = 1:2
            expected = tests.infrastructure.elevate(A.coeffs(cellIndex), A.Degree, A.Degree+2);
            tests.infrastructure.verify_expr(testCase, B.coeffs(cellIndex), expected);
        end
        testCase.verifyEqual(A.LocalValues, saved);
        testCase.verifyEqual(B.NumRateRows, A.NumRateRows);
        testCase.verifyEqual(B.RateBounds, A.RateBounds);
        testCase.verifyEqual(B.IsContinuous, A.IsContinuous);
    end
    % Unequal degrees, rectangular payloads and distinct later-cell rate rows
    % detect both tensor-index errors and reuse of a kernel with wrong width.
    grid = {[0 .4 1], [-2 0 3]};
    vals = helper.mkNest([2 2], @tensorLeaf);
    A = pdmat(grid, vals, Degree=[1 2], RateBounds=[-1 2; -3 4]);
    for mode = ["fast", "strict"]
        B = A.elevate([2 1], mode);
        for subs = A.cells()'
            expected = tests.infrastructure.elevate(A.coeffs(subs'), [1 2], [3 3]);
            tests.infrastructure.verify_expr(testCase, B.coeffs(subs'), expected);
        end
    end
end
function test_zero_increment_does_not_admit_function_only_data(testCase)
    % A no-op degree request must still enforce the coefficient-evidence gate.
    F = pdmat({[0 2 5], [-1 3]}, @(x,y) sin(x+y));
    for mode = ["fast", "strict"]
        testCase.verifyError(@() F.elevate([0 0],mode), ...
            "pdbase:MissingCoefficientEvidence");
    end
    testCase.verifyEqual(F.evaluate([.5 1]), sin(1.5), AbsTol=1e-12);
end

function leaf = tensorLeaf(subs)
    % Every matrix entry, coefficient, row and physical cell is distinguishable.
    leaf = cell(4, 6);
    for row = 1:4
        for k = 1:6
            leaf{row,k} = reshape(1:6, 2, 3) + 100*subs(1) + ...
                10*subs(2) + row*k;
        end
    end
end

function test_object_api_requires_coefficients(testCase)
    % Function-only construction supplies no coefficient elevation evidence.
    source = pdmat({[0 1]}, @(rho) 1 + rho);
    testCase.verifyError(@() source.elevate(1), "pdbase:MissingCoefficientEvidence");
end
