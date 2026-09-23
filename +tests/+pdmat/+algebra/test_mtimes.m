function tests = test_mtimes
    % Behavioral regressions for pdmat.mtimes.
    tests = functiontests(localfunctions);
end

function test_square_constant_factors_preserve_written_order_for_numeric_storage(testCase)
    % Noncommuting square factors expose reversals as values, not shape errors.
    for convert={@double,@single,@sparse}
        cast=convert{1}; L=cast([1 2;0 3]); R=cast([0 -1;2 1]);
        values={{cast([1 3;2 5]),cast([7 -2;1 4]),cast([-3 6;8 2]),cast([4 1;-5 3])}, ...
            {cast([4 1;-5 3]),cast([2 -7;3 11]),cast([6 2;9 -1]),cast([1 4;7 2])}};
        A=pdmat([0 1 3],values,Degree=3); saved=A.LocalValues;
        left=L*A; right=A*R;
        for c=1:2
            actualLeft=left.coeffs(c); actualRight=right.coeffs(c);
            for k=1:4
                testCase.verifyEqual(full(double(actualLeft{k})), ...
                    full(double(L*values{c}{k})),AbsTol=1e-6);
                testCase.verifyEqual(full(double(actualRight{k})), ...
                    full(double(values{c}{k}*R)),AbsTol=1e-6);
            end
        end
        testCase.verifyEqual(left.Degree,3);
        testCase.verifyEqual(right.MatrixSize,[2 2]);
        testCase.verifyEqual(A.LocalValues,saved);
    end
end
function test_zero_valued_active_rate_tables_cannot_multiply_each_other(testCase)
    % Zero controls cannot bypass the prohibition on two active rate tables.
    A = pdmat([0 2 5], {1,3,7}, Degree=1, RateBounds=[0 0]);
    D = rhodiff(A);
    testCase.verifyEqual(D.NumRateRows, 1);
    testCase.verifyEqual(D.coeffs(2), {0});
    testCase.verifyError(@() D*D, "pdmat:InvalidMultiplication");
end

function test_function_only_zero_products_rejected(testCase)
    % Multiplication by zero must not turn placeholders into certified data.
    F = pdmat([0 1], @(x) [x 2*x; 3*x 1+x]);
    Z = pdmat([0 1], {zeros(2), zeros(2)}, Degree=1);
    saved = F.LocalValues;
    calls = {@() F * 0, @() 0 * F, @() F * zeros(2), ...
        @() zeros(2) * F, @() F * Z, @() Z * F};
    for k = 1:numel(calls)
        testCase.verifyError(calls{k}, "pdmat:FunctionOnlyAlgebra");
    end
    testCase.verifyEqual(F.LocalValues, saved);
end

function setupOnce(~)
    yalmip("clear");
end

function test_multi_cell_3_d_matrix_product(testCase)
    % A multi-cell 3-D matrix product must match the direct Bernstein sum.
    grid = {[0 0.5 1], [10 20], [-2 3]};
    leftDegree = [2 1 0];
    rightDegree = [1 0 2];
    leftValues = numericTree(grid, leftDegree, [2 3], 10);
    rightValues = numericTree(grid, rightDegree, [3 2], 100);
    A = pdmat(grid, leftValues, Degree=leftDegree);
    B = pdmat(grid, rightValues, Degree=rightDegree);

    C = A * B;

    testCase.verifyEqual(C.Degree, leftDegree + rightDegree);
    testCase.verifyEqual(C.GridInfo.Vectors, grid);
    testCase.verifyEqual(C.MatrixSize, [2 2]);
    cells = C.cells();
    for cellIndex = 1:size(cells, 1)
        subs = cells(cellIndex, :);
        expected = legacyBernProduct(A.coeffs(subs), leftDegree, ...
            B.coeffs(subs), rightDegree, 3);
        verifyCoefficientRow(testCase, C.coeffs(subs), expected, 1e-11);
    end
end

function test_degree_1030_finite_product_elevation_planning(testCase)
    % Degree 1030 must remain finite after product and elevation planning.
    coeffs = repmat({1}, 1, 516);
    factor = pdmat({[0 1]}, coeffs, Degree=515);

    product = factor * factor;
    productValues = cell2mat(product.coeffs(1));
    testCase.verifyTrue(all(isfinite(productValues)));
    testCase.verifyLessThanOrEqual(max(abs(productValues - 1)), 1e-10);

    constant = pdmat({[0 1]}, {1}, Degree=0);
    elevated = constant.elevate(1030);
    elevatedValues = cell2mat(elevated.coeffs(1));
    testCase.verifyTrue(all(isfinite(elevatedValues)));
    testCase.verifyLessThanOrEqual(max(abs(elevatedValues - 1)), 1e-10);
end

function test_matrix_multiplication_convolve_bernstein(testCase)
    % Matrix multiplication should convolve Bernstein coefficients and grow degree.
    A = pdmat({[0 1]}, {[1 2], [3 4]}, Degree=1);
    B = pdmat({[0 1]}, {[5; 6], [7; 8]}, Degree=1);

    C = A * B;

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyEqual(size(C), [1 1]);
    tests.infrastructure.verify_coeff(testCase, C, 1, {17, 31, 53});
end

function test_scalar_scaling_preserve_complete_derivative_rate(testCase)
    % Scalar scaling should preserve one complete derivative rate-row table.
    rb = [-1 2];
    scalarData = pdmat([0 1], {1, 3}, Degree=1, RateBounds=rb);
    matrixData = pdmat([0 1], {eye(2), 2 * eye(2)}, ...
        Degree=1, RateBounds=rb);
    ordinaryScalar = pdmat([0 1], {2, 4}, Degree=1);
    ordinaryMatrix = pdmat([0 1], {eye(2), 2 * eye(2)}, Degree=1);
    derivativeScalar = rhodiff(scalarData);
    derivativeMatrix = rhodiff(matrixData);
    expected = {
        -2 * eye(2), -4 * eye(2)
        4 * eye(2), 8 * eye(2)
        };

    products = {
        derivativeScalar * ordinaryMatrix, ...
        ordinaryMatrix * derivativeScalar, ...
        ordinaryScalar * derivativeMatrix, ...
        derivativeMatrix * ordinaryScalar
        };
    for k = 1:numel(products)
        product = products{k};
        testCase.verifyEqual(product.Degree, 1);
        testCase.verifyEqual(product.coeffs(1), expected, AbsTol=1e-10);
        verifyRateMeta(testCase, product, [2 2]);
    end

    testCase.verifyError(@() derivativeScalar * derivativeMatrix, ...
        "pdmat:InvalidMultiplication");
    testCase.verifyError(@() derivativeMatrix * derivativeScalar, ...
        "pdmat:InvalidMultiplication");
end

function test_product_validation_distinct_rate_vertices_2(testCase)
    % Product validation must use distinct rate vertices, not 2^npar rows.
    [D, A] = fixedTensorRateData();

    C = D * A;

    testCase.verifyEqual(C.NumRateRows, 2);
    testCase.verifyEqual(size(C.coeffs([1 1]), 1), 2);
    testCase.verifyEqual(C.RateBounds, D.RateBounds);
end

function test_fixed_rate_box_still_represents_rate(testCase)
    % A fixed rate box still represents rate rows on both product sides.
    source = pdmat([0 2], {1, 5}, Degree=1, RateBounds=[3 3]);
    D = rhodiff(source);

    testCase.verifyEqual(D.NumRateRows, 1);
    testCase.verifyError(@() D * D, "pdmat:InvalidMultiplication");
end

function test_scalar_sdpvar_scalar_pdmat_broadcast_both(testCase)
    % A scalar sdpvar and scalar pdmat should broadcast in both orders.
    x = sdpvar(1, 1);
    X = sdpvar(2, 2, 'full');
    A = pdmat([0 1], {eye(2), 2 * eye(2)}, Degree=1);
    S = pdmat([0 1], {2, 3, 4}, Degree=2);

    sdpLeft = x * A;
    sdpRight = A * x;
    knownLeft = S * X;
    knownRight = X * S;

    verifyScalarProduct(testCase, sdpLeft, [2 2], 1, ...
        {x * eye(2), x * 2 * eye(2)}, getvariables(x));
    verifyScalarProduct(testCase, sdpRight, [2 2], 1, ...
        {eye(2) * x, 2 * eye(2) * x}, getvariables(x));
    verifyScalarProduct(testCase, knownLeft, [2 2], 2, ...
        {2 * X, 3 * X, 4 * X}, getvariables(X));
    verifyScalarProduct(testCase, knownRight, [2 2], 2, ...
        {X * 2, X * 3, X * 4}, getvariables(X));
end

function test_compatible_affine_known_matrices_multiply_either(testCase)
    % Compatible affine and known matrices multiply in either operand order.
    X = sdpvar(2, 3, 'full');
    Y = sdpvar(4, 2, 'full');
    a0 = reshape(1:12, 3, 4);
    a1 = a0 + 20;
    a2 = a0 - 7;
    A = pdmat({[0 0.5 1]}, {a0, a1, a2}, Degree=1);

    sdpLeft = X * A;
    knownLeft = A * Y;

    testCase.verifyClass(sdpLeft, "pdvar");
    testCase.verifyClass(knownLeft, "pdvar");
    testCase.verifyEqual(size(sdpLeft), [2 4]);
    testCase.verifyEqual(size(knownLeft), [3 2]);
    testCase.verifyEqual(sdpLeft.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(knownLeft.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(sdpLeft.Degree, 1);
    testCase.verifyEqual(knownLeft.Degree, 1);
    testCase.verifyTrue(sdpLeft.IsContinuous);
    testCase.verifyTrue(knownLeft.IsContinuous);
    testCase.verifyEqual(multiplication_objectVariables(sdpLeft), getvariables(X));
    testCase.verifyEqual(multiplication_objectVariables(knownLeft), getvariables(Y));
    tests.infrastructure.verify_expr(testCase, sdpLeft.coeffs(1), {X * a0, X * a1});
    tests.infrastructure.verify_expr(testCase, sdpLeft.coeffs(2), {X * a1, X * a2});
    tests.infrastructure.verify_expr(testCase, knownLeft.coeffs(1), {a0 * Y, a1 * Y});
    tests.infrastructure.verify_expr(testCase, knownLeft.coeffs(2), {a1 * Y, a2 * Y});

    vars = unique([getvariables(X), getvariables(Y)]);
    assign(recover(vars), 1:numel(vars));
    for rho = [0 0.25 0.5 0.75 1]
        known = A.evaluate(rho);
        testCase.verifyEqual(value(sdpLeft.evaluate(rho)), ...
            value(X) * known, AbsTol=1e-10);
        testCase.verifyEqual(value(knownLeft.evaluate(rho)), ...
            known * value(Y), AbsTol=1e-10);
    end
end

function test_symbolic_scaling_matrix_products_known_data(testCase)
    % Symbolic scaling and matrix products retain every known-data rate row.
    rb = [-1 2];
    x = sdpvar(1, 1);
    X = sdpvar(2, 2, 'full');
    L = sdpvar(3, 2, 'full');
    R = sdpvar(2, 4, 'full');
    matrixData = pdmat([0 1], {{ ...
        eye(2), 2 * eye(2); ...
        3 * eye(2), 4 * eye(2)}}, Degree=1, RateBounds=rb);
    scalarData = pdmat([0 1], {{1, 2; 10, 14}}, ...
        Degree=1, RateBounds=rb);

    multiplication_verifySdpRateProduct(testCase, x * matrixData, ...
        {x * eye(2), x * 2 * eye(2); ...
        x * 3 * eye(2), x * 4 * eye(2)}, getvariables(x));
    multiplication_verifySdpRateProduct(testCase, matrixData * x, ...
        {eye(2) * x, 2 * eye(2) * x; ...
        3 * eye(2) * x, 4 * eye(2) * x}, getvariables(x));
    multiplication_verifySdpRateProduct(testCase, scalarData * X, ...
        {X, 2 * X; 10 * X, 14 * X}, getvariables(X));
    multiplication_verifySdpRateProduct(testCase, X * scalarData, ...
        {X, X * 2; X * 10, X * 14}, getvariables(X));

    leftProduct = L * matrixData;
    rightProduct = matrixData * R;
    testCase.verifyClass(leftProduct, "pdvar");
    testCase.verifyClass(rightProduct, "pdvar");
    testCase.verifyEqual(size(leftProduct), [3 2]);
    testCase.verifyEqual(size(rightProduct), [2 4]);
    testCase.verifyEqual(leftProduct.RateBounds, rb);
    testCase.verifyEqual(rightProduct.RateBounds, rb);
    testCase.verifyEqual(leftProduct.NumRateRows, 2);
    testCase.verifyEqual(rightProduct.NumRateRows, 2);
    testCase.verifyEqual(multiplication_objectVariables(leftProduct), getvariables(L));
    testCase.verifyEqual(multiplication_objectVariables(rightProduct), getvariables(R));
    tests.infrastructure.verify_expr(testCase, leftProduct.coeffs(1), { ...
        L, L * 2; L * 3, L * 4});
    tests.infrastructure.verify_expr(testCase, rightProduct.coeffs(1), { ...
        R, 2 * R; 3 * R, 4 * R});
end

function test_proven_known_zeros_compact_zero_product(testCase)
    % Proven known zeros should keep the compact zero-product contract.
    x = sdpvar(1, 1);
    X = sdpvar(2, 2, 'full');
    scalarZero = pdmat([0 1], {0, 0, 0}, Degree=2);
    matrixZero = pdmat([0 1], {zeros(2), zeros(2)}, Degree=1);
    rectZero = pdmat([0 1], {zeros(3, 4), zeros(3, 4)}, Degree=1);
    L = sdpvar(2, 3, 'full');
    R = sdpvar(4, 2, 'full');

    verifyZeroPdvar(testCase, scalarZero * X, [2 2]);
    verifyZeroPdvar(testCase, X * scalarZero, [2 2]);
    verifyZeroPdvar(testCase, x * matrixZero, [2 2]);
    verifyZeroPdvar(testCase, matrixZero * x, [2 2]);
    verifyZeroPdvar(testCase, L * rectZero, [2 4]);
    verifyZeroPdvar(testCase, rectZero * R, [3 2]);
end

function test_matrix_bridge_preserves_dimension_coefficient(testCase)
    % The matrix bridge preserves dimension and coefficient-evidence guards.
    x = sdpvar(1, 1);
    y = sdpvar(1, 1);
    X = sdpvar(3, 4, 'full');
    A = pdmat([0 1], {eye(2), 2 * eye(2)}, Degree=1);
    F = pdmat([0 1], @(rho) rho);
    nonlinear = x * y;
    complexScalar = x + 1i * y;

    testCase.verifyError(@() A * X, "pdmat:InvalidMultiplication");
    testCase.verifyError(@() X * A, "pdmat:InvalidMultiplication");
    testCase.verifyError(@() nonlinear * A, "pdmat:InvalidMultiplication");
    testCase.verifyError(@() A * complexScalar, "pdmat:InvalidMultiplication");
    testCase.verifyError(@() F * X, "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() X * F, "pdmat:FunctionOnlyAlgebra");
end

function test_metadata_only_known_bounds_ordinary_rows(testCase)
    % Metadata-only known bounds remain ordinary rows in the hidden bridge.
    rb = [-1 2];
    X = sdpvar(3, 4, 'full');
    Y = sdpvar(4, 2, 'full');
    a0 = reshape(1:6, 2, 3);
    a1 = a0 + 10;
    R = pdmat([0 1], {a0, a1}, Degree=1, RateBounds=rb);

    L = R * X;
    U = Y * R;

    testCase.verifyEqual(size(L), [2 4]);
    testCase.verifyEqual(size(U), [4 3]);
    testCase.verifyEqual(L.RateBounds, rb);
    testCase.verifyEqual(U.RateBounds, rb);
    testCase.verifyEqual(L.NumRateRows, 0);
    testCase.verifyEqual(U.NumRateRows, 0);
    testCase.verifyEqual(multiplication_objectVariables(L), getvariables(X));
    testCase.verifyEqual(multiplication_objectVariables(U), getvariables(Y));
    tests.infrastructure.verify_expr(testCase, L.coeffs(1), {a0 * X, a1 * X});
    tests.infrastructure.verify_expr(testCase, U.coeffs(1), {Y * a0, Y * a1});
end

function values = numericTree(grid, degree, matrixSize, offset)
    % Build deterministic nested local data on every physical tensor cell.
    nCell = cellfun(@numel, grid) - 1;
    degree = expandDegree(degree, numel(grid));
    labels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, degree, ...
        "UniformOutput", false));
    values = helper.mkNest(nCell, @makeLeaf);

    function leaf = makeLeaf(subs)
        leaf = cell(1, size(labels, 1));
        for coefficient = 1:numel(leaf)
            globalLabel = (subs - 1) .* degree + labels(coefficient, :);
            base = offset + 10 * sum(globalLabel .* 10 .^ (0:numel(degree) - 1));
            leaf{coefficient} = reshape( ...
                base + (1:prod(matrixSize)), matrixSize);
        end
    end
end

function out = legacyBernProduct(lhs, lhsDegree, rhs, rhsDegree, nParameters)
    % Direct pair-sum oracle independent of product-plan implementation.
    lhsDegree = expandDegree(lhsDegree, nParameters);
    rhsDegree = expandDegree(rhsDegree, nParameters);
    outputDegree = lhsDegree + rhsDegree;
    lhsLabels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, lhsDegree, ...
        "UniformOutput", false));
    outputLabels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, ...
        outputDegree, "UniformOutput", false));
    out = cell(1, size(outputLabels, 1));
    for outputIndex = 1:size(outputLabels, 1)
        outputLabel = outputLabels(outputIndex, :);
        accumulator = [];
        for lhsIndex = 1:size(lhsLabels, 1)
            lhsLabel = lhsLabels(lhsIndex, :);
            rhsLabel = outputLabel - lhsLabel;
            if any(rhsLabel < 0) || any(rhsLabel > rhsDegree)
                continue
            end
            rhsIndex = labelIndex(rhsLabel, rhsDegree);
            scale = productScale(lhsLabel, lhsDegree, ...
                rhsLabel, rhsDegree, outputLabel);
            term = (lhs{lhsIndex} * rhs{rhsIndex}) .* scale;
            if isempty(accumulator)
                accumulator = term;
            else
                accumulator = accumulator + term;
            end
        end
        out{outputIndex} = accumulator;
    end
end

function verifyCoefficientRow(testCase, actual, expected, tolerance)
    % Compare numeric coefficient rows without loosening tensor indexing.
    testCase.verifyEqual(size(actual), size(expected));
    for coefficient = 1:numel(actual)
        scale = max(1, norm(expected{coefficient}, "fro"));
        testCase.verifyLessThanOrEqual( ...
            norm(actual{coefficient} - expected{coefficient}, "fro"), ...
            tolerance * scale);
    end
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

function verifyRateMeta(testCase, obj, sz)
    % Explicit rows remain rate-dependent and preserve their matrix shape.
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.RateBounds, [-1 2]);
    testCase.verifyEqual(size(obj.coeffs(1), 1), 2);
end

function verifyScalarProduct(testCase, obj, sz, deg, expected, vars)
    % Check scalar broadcasting without introducing new YALMIP decisions.
    testCase.verifyClass(obj, "pdvar");
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.Degree, deg);
    testCase.verifyEqual(obj.GridInfo.Vectors{1}, [0 1]);
    testCase.verifyEqual(multiplication_objectVariables(obj), unique(vars));
    tests.infrastructure.verify_expr(testCase, obj.coeffs(1), expected);
end

function verifyZeroPdvar(testCase, obj, sz)
    % Zero product shortcuts should return compact ordinary coefficients.
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.Degree, zeros(1, obj.npar()));
    testCase.verifyFalse(obj.ContainsDecision);
    testCase.verifyEmpty(obj.RateBounds);
    coeffs = obj.coeffs(ones(1, obj.npar()));
    testCase.verifyEqual(numel(coeffs), 1);
    testCase.verifyEqual(coeffs{1}, zeros(sz));
end

function vars = multiplication_objectVariables(obj)
    % Collect unique symbolic identifiers across the complete coefficient tree.
    vars = [];
    cells = obj.cells();
    for k = 1:size(cells, 1)
        coeffs = obj.coeffs(cells(k, :));
        for j = 1:numel(coeffs)
            if isa(coeffs{j}, "sdpvar")
                vars = [vars, getvariables(coeffs{j})]; %#ok<AGROW>
            end
        end
    end
    vars = unique(vars);
end
function multiplication_verifySdpRateProduct(testCase, obj, expected, vars)
    % Check the complete explicit rate-row table after symbolic scaling.
    testCase.verifyClass(obj, "pdvar");
    testCase.verifyEqual(size(obj), [2 2]);
    testCase.verifyEqual(obj.Degree, 1);
    testCase.verifyEqual(obj.RateBounds, [-1 2]);
    testCase.verifyEqual(obj.NumRateRows, 2);
    testCase.verifyEqual(multiplication_objectVariables(obj), unique(vars));
    tests.infrastructure.verify_expr(testCase, obj.coeffs(1), expected);
end

function scale = productScale(lhsLabel, lhsDegree, rhsLabel, ...
        rhsDegree, outputLabel)
    % Return the tensor Bernstein product normalization.
    outputDegree = lhsDegree + rhsDegree;
    scale = 1;
    for parameter = 1:numel(outputLabel)
        scale = scale ...
            * nchoosek(lhsDegree(parameter), lhsLabel(parameter)) ...
            * nchoosek(rhsDegree(parameter), rhsLabel(parameter)) ...
            / nchoosek(outputDegree(parameter), outputLabel(parameter));
    end
end

function index = labelIndex(label, degree)
    % Convert repository mixed-radix label order to a one-based index.
    multipliers = fliplr(cumprod([1, fliplr(degree(2:end) + 1)]));
    index = label * multipliers' + 1;
end

function degree = expandDegree(degree, nParameters)
    % Expand scalar shorthand without sharing production normalizer logic.
    degree = reshape(degree, 1, []);
    if isscalar(degree)
        degree = repmat(degree, 1, nParameters);
    end
end

function test_noncommuting_matrix_products_all_rows(testCase)
    A = tests.infrastructure.fixture("pdmat", true);
    B = pdmat([0 2 5], {[2 3;-5 7],[11 -13;17 19],[23 29;31 -37]}, Degree=1);
    left = A*B;
    right = B*A;
    for cellIndex = 1:2
        a = A.coeffs(cellIndex);
        b = B.coeffs(cellIndex);
        expectedL = cell(2,3); expectedR = cell(2,3);
        for row = 1:2
            expectedL(row,:) = {a{row,1}*b{1}, (a{row,1}*b{2}+a{row,2}*b{1})/2, a{row,2}*b{2}};
            expectedR(row,:) = {b{1}*a{row,1}, (b{1}*a{row,2}+b{2}*a{row,1})/2, b{2}*a{row,2}};
        end
        tests.infrastructure.verify_expr(testCase,left.coeffs(cellIndex),expectedL);
        tests.infrastructure.verify_expr(testCase,right.coeffs(cellIndex),expectedR);
    end
    testCase.verifyEqual(left.Degree,2);
    testCase.verifyEqual(right.NumRateRows,2);
end
