function tests = test_uplus
    % Public pdmat.uplus behavioral contracts.
    tests = functiontests(localfunctions);
end
function test_function_only_identity_preserves_exact_evaluator(testCase)
    % This identity operation does not claim coefficient evidence.
    F = pdmat([0 2 5], @(x) [sin(x); exp(x)]);
    A = +F;
    testCase.verifyTrue(isequal(A.FunctionHandle, F.FunctionHandle));
    testCase.verifyEqual(A.SourceSummary, "function");
    testCase.verifyEqual(A.MatrixSize, [2 1]);
    testCase.verifyEqual(A.LocalValues, F.LocalValues);
    testCase.verifyEqual(A.evaluate(.4), [sin(.4); exp(.4)], AbsTol=1e-12);
    testCase.verifyError(@() A * 2, "pdmat:FunctionOnlyAlgebra");
end

function test_fixed_rate_identity_copy_does_not_alias_source(testCase)
    % A one-row derivative retains active-rate metadata and value semantics.
    F = pdmat([0 2 5], {[1 4 9], [5 12 21], [17 30 45]}, ...
        Degree=1, RateBounds=[3 3]);
    F = rhodiff(F);
    saved = F.LocalValues;
    A = +F;
    testCase.verifyEqual(A.NumRateRows, 1);
    testCase.verifyEqual(A.RateBounds, [3 3]);
    testCase.verifyEqual(A.MatrixSize, [1 3]);
    A(1,2) = 101;
    for cellIndex = 1:2
        coeff = A.coeffs(cellIndex);
        expected = saved{cellIndex};
        expected{1}(1,2) = 101;
        testCase.verifyEqual(coeff, expected);
    end
    testCase.verifyEqual(F.LocalValues, saved);
end

function test_all_cells_and_rate_rows(testCase)
    % Compare complete payloads, including symbolic identities and source state.
    tests.infrastructure.verify_transform(testCase, "pdmat", @(x) +x);
end
