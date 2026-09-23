function tests = test_algebra_integration
    % Behavioral regressions for pdmat.algebra_integration.
    tests = functiontests(localfunctions);
end

function test_discontinuous_refinement_composes_with_arithmetic_and_blocks(testCase)
    % All operators must preserve each side of the same interior source jump.
    L=[1 2;3 5]; R=[7 -2;4 1]; U=[20 3;-1 8]; V=[2 30;7 -5]; N=[2 1;-3 4];
    A=pdmat([0 .5 1],{{L,R},{U,V}},Degree=1); saved=A.LocalValues;
    B=pdmat([0 .25 .5 .75 1],{{N},{N},{N},{N}},Degree=0);
    restricted={{L,(L+R)/2},{(L+R)/2,R},{U,(U+V)/2},{(U+V)/2,V}};
    operations={@plus,@minus,@mtimes,@(x,y) cat(2,x,y),@blkdiag};
    for index=1:numel(operations)
        operation=operations{index}; actual=operation(A,B);
        for c=1:4
            expected=cellfun(@(x) operation(x,N),restricted{c},UniformOutput=false);
            testCase.verifyEqual(actual.coeffs(c),expected,AbsTol=1e-12);
        end
    end
    testCase.verifyEqual(A.LocalValues,saved);
end
function test_tensor_refinement_product_transpose_and_reduction(testCase)
    % Noncommuting products must remain correct through several shape operations.
    f = @(x,y) [x^2+y, 1+x; 2*y, x-y];
    g = @(x,y) [1+y^2, x; x-y, 2+y];
    A = pdmat({[0 .5 2], [-1 3]}, f, Degree=[2 1]);
    B = pdmat({[0 2], [-1 0 3]}, g, Degree=[1 2]);
    C = sum((A*B-B*A).',2);
    testCase.verifyEqual(C.Degree, [3 3]);
    testCase.verifyEqual(C.GridInfo.Vectors, {[0 .5 2], [-1 0 3]});
    for x = [0 .25 .5 1.25 2]
        for y = [-1 -.5 0 1.5 3]
            expected = sum((f(x,y)*g(x,y)-g(x,y)*f(x,y)).',2);
            testCase.verifyEqual(C.evaluate([x y]), expected, AbsTol=1e-9);
        end
    end
end

function test_subtraction_unary_minus_operate_coefficient_wise(testCase)
    % Subtraction and unary minus should operate coefficient-wise.
    A = pdmat({[0 1]}, {1, 3}, Degree=1);
    B = pdmat({[0 1]}, {4, 8}, Degree=1);

    tests.infrastructure.verify_coeff(testCase, B - A, 1, {3, 5});
    tests.infrastructure.verify_coeff(testCase, -A, 1, {-1, -3});
end

function test_chained_scalar_products_cubic_bernstein_coefficients(testCase)
    % Chained scalar products should retain cubic Bernstein coefficients.
    A = pdmat({[0 1]}, {2, 5}, Degree=1);
    B = pdmat({[0 1]}, {7, 11}, Degree=1);
    C = pdmat({[0 1]}, {3, 4}, Degree=1);

    L = A * B * C;

    testCase.verifyEqual(L.Degree, 3);
    tests.infrastructure.verify_coeff(testCase, L, 1, {42, 227 / 3, 131, 220});
end

function test_tensor_grid_products_preserve_tensor_coefficient(testCase)
    % Tensor-grid products should preserve tensor coefficient ordering.
    grid = {[0 1], [10 20]};
    A = pdmat(grid, {1 2; 3 4}, Degree=[1 1]);
    B = pdmat(grid, {5 6; 7 8}, Degree=[1 1]);

    K = A * B;
    coeffs = K.coeffs([1 1]);

    testCase.verifyEqual(K.Degree, [2 2]);
    testCase.verifyEqual(size(K), [1 1]);
    testCase.verifyEqual(numel(coeffs), 9);
    testCase.verifyEqual(coeffs{1}, 5);
    testCase.verifyEqual(coeffs{5}, 15);
    testCase.verifyEqual(coeffs{9}, 32);
end

function test_2_d_degree_2_by_degree(testCase)
    % A 2-D degree-2 by degree-1 product should use tensor binomial scaling.
    grid = {[0 1], [10 20]};
    Adata = cell(3, 3);
    Bdata = cell(2, 2);
    for i = 0:2
        for j = 0:2
            Adata{i + 1, j + 1} = i + 10 * j;
        end
    end
    for i = 0:1
        for j = 0:1
            Bdata{i + 1, j + 1} = 100 + i + 10 * j;
        end
    end
    A = pdmat(grid, Adata, Degree=[2 2]);
    B = pdmat(grid, Bdata, Degree=[1 1]);

    C = A * B;

    testCase.verifyEqual(C.Degree, [3 3]);
    tests.infrastructure.verify_coeff(testCase, C, [1 1], ...
        bernProdExpected(A.coeffs([1 1]), 2, B.coeffs([1 1]), 1, 2));
end

function test_same_bound_mixed_scalar_grids_align(testCase)
    % Same-bound mixed scalar grids should align on a common refinement.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);
    B = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);

    S = A + B;
    P = A * B;

    testCase.verifyEqual(S.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(P.GridInfo.Vectors{1}, [0 0.5 1]);
    tests.infrastructure.verify_coeff(testCase, S, 1, {11, 21.5});
    tests.infrastructure.verify_coeff(testCase, S, 2, {21.5, 32});
    tests.infrastructure.verify_coeff(testCase, P, 1, {10, 17.5, 30});
    tests.infrastructure.verify_coeff(testCase, P, 2, {30, 42.5, 60});
end

function test_same_bound_tensor_grids_refine_each(testCase)
    % Same-bound tensor grids should refine each affected physical axis.
    A = pdmat({[0 1], [0 1]}, {1 2; 3 4}, Degree=[1 1]);
    B = pdmat({[0 0.5 1], [0 1]}, {10 20; 30 40; 50 60}, Degree=[1 1]);

    S = A + B;

    testCase.verifyEqual(S.GridInfo.Vectors, {[0 0.5 1], [0 1]});
    tests.infrastructure.verify_coeff(testCase, S, [1 1], {11, 22, 32, 43});
    tests.infrastructure.verify_coeff(testCase, S, [2 1], {32, 43, 53, 64});
end

function test_zero_rate_table_broadcast_rows_instead(testCase)
    % A zero rate table must broadcast its rows instead of losing rate metadata.
    rb = [-1 2];
    Z = pdmat([0 1], {{0, 0; 0, 0}}, Degree=1, RateBounds=rb);
    A = pdmat([0 1], {3, 5}, Degree=1);

    S = Z + A;

    testCase.verifyEqual(S.RateBounds, rb);
    testCase.verifyEqual(S.coeffs(1), {3, 5; 3, 5});
end

function test_zero_rate_row_products_still_normalize(testCase)
    % Zero rate-row products still normalize both operands before collapse.
    Z = pdmat([0 1], {{0, 0; 0, 0}}, Degree=1, RateBounds=[-1 2]);
    A = pdmat([0 1], {3, 5}, Degree=1);

    left = Z * A;
    right = A * Z;

    testCase.verifyTrue(helper.isZero(left, "obj"));
    testCase.verifyTrue(helper.isZero(right, "obj"));
    testCase.verifyEqual(size(left), [1 1]);
    testCase.verifyEqual(size(right), [1 1]);
end

function test_numeric_matrices_multiply_pdmat_operands_either(testCase)
    % Numeric matrices should multiply pdmat operands on either side.
    A = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);

    L = [1 0] * A;
    R = A * [1; 2];

    testCase.verifyEqual(size(L), [1 2]);
    testCase.verifyEqual(size(R), [2 1]);
    tests.infrastructure.verify_coeff(testCase, L, 1, {[1 2], [5 6]});
    tests.infrastructure.verify_coeff(testCase, R, 1, {[5; 11], [17; 23]});
end

function test_degree_alignment_componentwise_while_product_degrees(testCase)
    % Degree alignment is componentwise while product degrees add by axis.
    grid = {[0 1], [10 20]};
    addLeft = cell(2, 4);
    addRight = cell(3, 2);
    for i = 0:1
        for j = 0:3
            addLeft{i + 1, j + 1} = i;
        end
    end
    for i = 0:2
        for j = 0:1
            addRight{i + 1, j + 1} = 10 * j;
        end
    end
    A = pdmat(grid, addLeft, Degree=[1 3]);
    B = pdmat(grid, addRight, Degree=[2 1]);

    sumObj = A + B;
    difference = A - B;
    labels = helper.combRows({0:2, 0:3});
    expectedSum = num2cell(labels(:, 1) ./ 2 + ...
        10 .* labels(:, 2) ./ 3).';
    expectedDifference = num2cell(labels(:, 1) ./ 2 - ...
        10 .* labels(:, 2) ./ 3).';

    testCase.verifyEqual(sumObj.Degree, [2 3]);
    testCase.verifyEqual(difference.Degree, [2 3]);
    tests.infrastructure.verify_coeff(testCase, sumObj, [1 1], expectedSum);
    tests.infrastructure.verify_coeff(testCase, difference, [1 1], expectedDifference);

    productLeft = cell(2, 3);
    productRight = cell(3, 2);
    for i = 0:1
        for j = 0:2
            productLeft{i + 1, j + 1} = i;
        end
    end
    for i = 0:2
        for j = 0:1
            productRight{i + 1, j + 1} = j;
        end
    end
    P = pdmat(grid, productLeft, Degree=[1 2]);
    Q = pdmat(grid, productRight, Degree=[2 1]);
    product = P * Q;
    productLabels = helper.combRows({0:3, 0:3});
    expectedProduct = num2cell( ...
        (productLabels(:, 1) ./ 3) .* ...
        (productLabels(:, 2) ./ 3)).';

    testCase.verifyEqual(product.Degree, [3 3]);
    tests.infrastructure.verify_coeff(testCase, product, [1 1], expectedProduct);
end

function test_numeric_promotion_preserve_direction_that_exactly(testCase)
    % Numeric promotion must preserve a direction that is exactly constant.
    grid = {[0 1], [10 20]};
    A = pdmat(grid, {1, 2, 3}, Degree=[0 2]);
    plusRight = A + 2;
    plusLeft = 2 + A;
    timesRight = A * 2;
    timesLeft = 2 * A;

    testCase.verifyEqual(plusRight.Degree, [0 2]);
    testCase.verifyEqual(plusLeft.Degree, [0 2]);
    testCase.verifyEqual(timesRight.Degree, [0 2]);
    testCase.verifyEqual(timesLeft.Degree, [0 2]);
    tests.infrastructure.verify_coeff(testCase, plusRight, [1 1], {3, 4, 5});
    tests.infrastructure.verify_coeff(testCase, plusLeft, [1 1], {3, 4, 5});
    tests.infrastructure.verify_coeff(testCase, timesRight, [1 1], {2, 4, 6});
    tests.infrastructure.verify_coeff(testCase, timesLeft, [1 1], {2, 4, 6});
end

function test_1_by_1_pdmat_scale_matrices(testCase)
    % A 1-by-1 pdmat should scale matrices in either operand order.
    S = pdmat({[0 1]}, {2, 4}, Degree=1);
    M = [1 2; 3 4];
    A = pdmat({[0 0.5 1]}, ...
        {eye(2), 2 * eye(2), 3 * eye(2)}, Degree=1);
    F = pdmat({[0 1]}, @(rho) 1 + rho, Degree=1);

    numericRight = S * M;
    numericLeft = M * S;
    knownRight = S * A;
    knownLeft = A * S;

    testCase.verifyClass(numericRight, "pdmat");
    testCase.verifyClass(numericLeft, "pdmat");
    testCase.verifyEqual(size(numericRight), [2 2]);
    testCase.verifyEqual(size(numericLeft), [2 2]);
    testCase.verifyEqual(numericRight.Degree, 1);
    testCase.verifyEqual(numericLeft.Degree, 1);
    tests.infrastructure.verify_coeff(testCase, numericRight, 1, {2 * M, 4 * M});
    tests.infrastructure.verify_coeff(testCase, numericLeft, 1, {2 * M, 4 * M});

    testCase.verifyEqual(knownRight.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(knownLeft.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(size(knownRight), [2 2]);
    testCase.verifyEqual(size(knownLeft), [2 2]);
    testCase.verifyEqual(knownRight.Degree, 2);
    testCase.verifyEqual(knownLeft.Degree, 2);
    tests.infrastructure.verify_coeff(testCase, knownRight, 1, ...
        {2 * eye(2), 3.5 * eye(2), 6 * eye(2)});
    tests.infrastructure.verify_coeff(testCase, knownLeft, 1, ...
        {2 * eye(2), 3.5 * eye(2), 6 * eye(2)});
    tests.infrastructure.verify_coeff(testCase, knownRight, 2, ...
        {6 * eye(2), 8.5 * eye(2), 12 * eye(2)});
    tests.infrastructure.verify_coeff(testCase, knownLeft, 2, ...
        {6 * eye(2), 8.5 * eye(2), 12 * eye(2)});
    tests.infrastructure.verify_coeff(testCase, F * M, 1, {M, 2 * M});
    tests.infrastructure.verify_coeff(testCase, M * F, 1, {M, 2 * M});
end

function test_algebra_reject_size_grid_bound_function(testCase)
    % Algebra should reject size, grid-bound, and function-only incompatibilities.
    A = pdmat({[0 1]}, {ones(1, 2), 2 * ones(1, 2)}, Degree=1);
    B = pdmat({[0 1]}, {1, 2}, Degree=1);
    C = pdmat({[0 2]}, {1, 2}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho);

    testCase.verifyError(@() A + B, "pdmat:InvalidAddition");
    testCase.verifyError(@() A * A, "pdmat:InvalidMultiplication");
    testCase.verifyError(@() B + C, "pdmat:MixedGrid");
    testCase.verifyError(@() F + 1, "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() F * eye(2), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() eye(2) * F, "pdmat:FunctionOnlyAlgebra");
end

function test_function_handles_bernstein_evidence_enter(testCase)
    % Function handles with Bernstein evidence should enter coefficient algebra.
    A = pdmat({[0 1]}, @(rho) rho, Degree=1);

    C = A + 1;

    testCase.verifyEqual(C.SourceSummary, "coefficient-backed");
    tests.infrastructure.verify_coeff(testCase, C, 1, {1, 2});
end

function test_linear_by_quadratic_handle_preserve_tensor(testCase)
    % A linear-by-quadratic handle should preserve its tensor degree in algebra.
    A = pdmat({[0 2], [10 14]}, @(rho, eta) rho + eta.^2, ...
        Degree=[1 2]);

    C = A + 1;

    testCase.verifyEqual(C.SourceSummary, "coefficient-backed");
    testCase.verifyEqual(C.Degree, [1 2]);
    tests.infrastructure.verify_coeff(testCase, C, [1 1], {101, 141, 197, 103, 143, 199});
    testCase.verifyEqual(C.evaluate([0.5 11]), 122.5, AbsTol=1e-10);
end

function test_algebra_preserve_discontinuity_without_repeating(testCase)
    % Algebra should preserve discontinuity without repeating constructor warnings.
    localValues = {{1, 2}, {3, 4}};
    A = constructWithWarning(testCase, ...
        @() pdmat({[0 1 2]}, localValues, Degree=1), ...
        "pdmat:DiscontinuousLocalValues");

    C = constructWarningFree(testCase, @() A + 1);

    testCase.verifyFalse(A.IsContinuous);
    testCase.verifyFalse(C.IsContinuous);
    tests.infrastructure.verify_coeff(testCase, C, 1, {2, 3});
    tests.infrastructure.verify_coeff(testCase, C, 2, {4, 5});
end

function test_provably_zero_arithmetic_return_compact_degree(testCase)
    % Provably zero arithmetic should return compact degree-zero data.
    A = pdmat({[0 1]}, {1, 3}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho * ones(2), Degree=1);

    Z1 = A - A;
    Z2 = A + (-A);
    Z3 = A * 0;
    Z4 = 0 * A;
    Z5 = F * 0;
    Z6 = Z1 * A;
    Z7 = Z1 * 2;
    Z8 = 2 * Z1;
    Z9 = Z1 * eye(2);
    Z10 = eye(2) * Z1;

    verifyZeroPdmat(testCase, Z1, [1 1]);
    verifyZeroPdmat(testCase, Z2, [1 1]);
    verifyZeroPdmat(testCase, Z3, [1 1]);
    verifyZeroPdmat(testCase, Z4, [1 1]);
    verifyZeroPdmat(testCase, Z5, [2 2]);
    verifyZeroPdmat(testCase, Z6, [1 1]);
    verifyZeroPdmat(testCase, Z7, [1 1]);
    verifyZeroPdmat(testCase, Z8, [1 1]);
    verifyZeroPdmat(testCase, Z9, [2 2]);
    verifyZeroPdmat(testCase, Z10, [2 2]);
    testCase.verifyTrue(isequal(A + Z1, A));
    testCase.verifyTrue(isequal(A - Z1, A));
    functionOnly = pdmat([0 1], @(rho) rho * ones(2));
    testCase.verifyError(@() functionOnly + 1, "pdmat:FunctionOnlyAlgebra");
end

function test_zero_numeric_matrices_still_enforce_matrix(testCase)
    % Zero numeric matrices should still enforce matrix-product dimensions.
    A = pdmat({[0 1]}, {ones(2, 3), 2 * ones(2, 3)}, Degree=1);

    L = zeros(4, 2) * A;
    R = A * zeros(3, 5);

    verifyZeroPdmat(testCase, L, [4 3]);
    verifyZeroPdmat(testCase, R, [2 5]);
    testCase.verifyError(@() A * zeros(4, 1), "pdmat:InvalidMultiplication");
end

function out = bernProdExpected(lhs, lhsDeg, rhs, rhsDeg, nPar)
    % Local oracle for tensor Bernstein product coefficients.
    outDeg = lhsDeg + rhsDeg;
    lhsLbls = helper.combRows(repmat({0:lhsDeg}, 1, nPar));
    outLbls = helper.combRows(repmat({0:outDeg}, 1, nPar));
    out = cell(1, size(outLbls, 1));
    for outIdx = 1:size(outLbls, 1)
        outLbl = outLbls(outIdx, :);
        acc = [];
        for lhsIdx = 1:size(lhsLbls, 1)
            lhsLbl = lhsLbls(lhsIdx, :);
            rhsLbl = outLbl - lhsLbl;
            if all(rhsLbl >= 0) && all(rhsLbl <= rhsDeg)
                rhsIdx = lblIdxExpected(rhsLbl, rhsDeg);
                term = lhs{lhsIdx} * rhs{rhsIdx} ...
                    * prodScaleExpected(lhsLbl, lhsDeg, rhsLbl, rhsDeg, outLbl);
                if isempty(acc)
                    acc = term;
                else
                    acc = acc + term;
                end
            end
        end
        out{outIdx} = acc;
    end
end

function verifyZeroPdmat(testCase, obj, sz)
    % Check the compact zero representation used by arithmetic fast paths.
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.Degree, zeros(1, obj.npar()));
    coeffs = obj.coeffs(ones(1, obj.npar()));
    testCase.verifyEqual(numel(coeffs), 1);
    testCase.verifyEqual(coeffs{1}, zeros(sz));
end

function obj = constructWithWarning(testCase, fcn, warningId)
    % Capture one direct-construction warning while retaining its result.
    obj = [];
    testCase.verifyWarning(@construct, warningId);

    function construct
        obj = fcn();
    end
end

function obj = constructWarningFree(testCase, fcn)
    % Capture an algebra result while asserting its internal rewrap is silent.
    obj = [];
    testCase.verifyWarningFree(@construct);

    function construct
        obj = fcn();
    end
end
function scale = prodScaleExpected(lhsLbl, lhsDeg, rhsLbl, rhsDeg, outLbl)
    outDeg = lhsDeg + rhsDeg;
    scale = 1;
    for k = 1:numel(outLbl)
        scale = scale ...
            * nchoosek(lhsDeg, lhsLbl(k)) ...
            * nchoosek(rhsDeg, rhsLbl(k)) ...
            / nchoosek(outDeg, outLbl(k));
    end
end

function idx = lblIdxExpected(lbl, deg)
    mult = (deg + 1) .^ (numel(lbl) - 1:-1:0);
    idx = sum(lbl .* mult) + 1;
end
