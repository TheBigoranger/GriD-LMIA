function tests = test_rhodiff
    % Behavioral regressions for pdmat.rhodiff.
    tests = functiontests(localfunctions);
end
function test_fixed_zero_rate_retains_derivative_identity_and_rejects_repeat(testCase)
    % Zero numerical derivative values do not erase active-rate semantics.
    A = pdmat({[0 2 5], [-1 3]}, @(x,y) [x^2+y, x*y], ...
        Degree=[2 1], RateBounds=zeros(2));
    D = rhodiff(A);
    for subs = D.cells()'
        testCase.verifyEqual(D.coeffs(subs'), repmat({zeros(1,2)},1,6));
    end
    testCase.verifyEqual(D.NumRateRows, 1);
    testCase.verifyEqual(D.RateBounds, zeros(2));
    testCase.verifyFalse(D.IsContinuous);
    testCase.verifyError(@() rhodiff(D), "pdmat:InvalidDiff");
end

function test_pdmat_differentiation_numeric_clears_exact_function(testCase)
    % pdmat differentiation remains numeric and clears exact function state.
    rb = [-2 3];
    A = pdmat([0 2], @(rho) rho.^2, Degree=2, RateBounds=rb);

    D = rhodiff(A);

    testCase.verifyClass(D, "pdmat");
    testCase.verifyEqual(D.Degree, 1);
    testCase.verifyEqual(D.coeffs(1), {0, -8; 0, 12}, AbsTol=1e-10);
    testCase.verifyFalse(D.ContainsDecision);
    testCase.verifyFalse(D.IsContinuous);
    testCase.verifyEqual(D.RateBounds, rb);
    testCase.verifyEqual(D.SourceSummary, "derivative");
    testCase.verifyEmpty(D.FunctionHandle);

    fixed = pdmat([0 2], {1, 5}, Degree=1, RateBounds=[3 3]);
    fixedD = rhodiff(fixed);
    testCase.verifyEqual(fixedD.coeffs(1), {6});
    testCase.verifyEqual(fixedD.NumRateRows, 1);
    fixedTbl = fixedD.bernTable();
    testCase.verifyEqual(vertcat(fixedTbl.RateVertex{:}), 3);
    testCase.verifyError(@() rhodiff(fixedD), "pdmat:InvalidDiff");
    shifted = fixedD + 1;
    testCase.verifyEqual(shifted.NumRateRows, 1);
    testCase.verifyEqual(fixedD(1, 1).NumRateRows, 1);

    exactOnly = pdmat([0 1], @(rho) rho, RateBounds=rb);
    rows = pdmat([0 1], {{1, 2; 3, 4}}, ...
        Degree=1, RateBounds=rb);
    testCase.verifyError(@() rhodiff(exactOnly), ...
        "pdmat:FunctionOnlyDiff");
    testCase.verifyError(@() rhodiff(rows), "pdmat:InvalidDiff");
end

function test_unequal_cell_widths_and_rate_signs(testCase)
    A = tests.infrastructure.fixture("pdmat", false);
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
    fixedSource = tests.infrastructure.fixture("pdmat", false, [4 4]);
    input = fixedSource.coeffs(2);
    fixed = rhodiff(fixedSource);
    testCase.verifyEqual(fixed.NumRateRows, 1);
    tests.infrastructure.verify_expr(testCase, fixed.coeffs(2), ...
        {8/3*(input{2}-input{1}), 8/3*(input{3}-input{2})});
end

function test_tensor_rate_order(testCase)
    % Dyadic unequal widths retain exact affine-basis comparisons.
    grid = {[0 1 3], [-2 0 4], [10 14]};
    rb = [-2 3; -5 7; -11 13];
    deg = [2 1 1];
    data = makeNumGrid(grid, deg, [2 2]);
    known = pdmat(grid, data, Degree=deg, RateBounds=rb);
    tests.infrastructure.verify_tensor_diff(testCase, known, rb, false);
end

function test_zero_degree_tensor_axis(testCase)
    % Dyadic unequal widths retain exact affine-basis comparisons.
    grid = {[0 1 3], [-2 0 4], [10 14]};
    rb = [-2 3; -5 7; -11 13];
    % A zero-degree axis retains its place in every rate vertex.
    deg = [2 0 1];
    data = makeNumGrid(grid, deg, [2 2]);
    source = pdmat(grid, data, Degree=deg, RateBounds=rb);
    actual = tests.infrastructure.verify_tensor_diff(testCase, source, rb, false);
    testCase.verifyEqual(actual.NumRateRows, 8);
end

function data = makeNumGrid(grid, deg, sz)
    % Build distinct matrix coefficients without depending on package traversal.
    dims = (cellfun(@numel, grid) - 1) .* deg + 1;
    data = cell(dims);
    nPar = numel(grid);
    for k = 1:numel(data)
        subs = cell(1, nPar);
        [subs{:}] = ind2sub(dims, k);
        key = sum((cell2mat(subs) - 1) .* 10 .^ (0:(nPar - 1)));
        data{k} = reshape(key + (1:prod(sz)), sz);
    end
end
