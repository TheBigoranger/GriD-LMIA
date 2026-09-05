function tests = test_elevate
    % Behavioral regressions for pdbase.elevate.
    tests = functiontests(localfunctions);
end

function test_nonuniform_tensor_mixed_rows_independent_incidence(testCase)
    % Unequal increments must preserve zero-axis incidence and every physical cell.
    grid = {[0 2 5],[-3 1 6]};
    vals = {{ {1,3,8;11,17,29}, {31,37,43;47,53,59} }, ...
        { {61,67,71;73,79,83}, {89,97,101;103,107,109} }};
    A = pdbase(grid,[1 1],[0 2],vals,RateBounds=[3 3;-2 5]);
    B = A.elevate([2 1],"strict");
    for i=1:2
        for j=1:2
            expected = tests.infrastructure.elevate(vals{i}{j},[0 2],[2 3]);
            tests.infrastructure.verify_expr(testCase,B.coeffs([i j]),expected);
        end
    end
    testCase.verifyEqual(B.NumRateRows,2);
    testCase.verifyEqual(B.GridInfo,A.GridInfo);
    testCase.verifyEqual(A.LocalValues,vals);
end

function setupOnce(~)
    yalmip("clear");
end

function test_public_coefficient_elevation_changes_basis_source(testCase)
    % Public coefficient elevation changes the basis, not source evidence.
    vals = {{0, 1}, {2, 4}};
    obj = pdbase({[0 1 2]}, [1 1], 1, vals);
    before = obj.LocalValues;

    same = obj.elevate(0);
    once = obj.elevate(1);
    twice = obj.elevate(2);

    testCase.verifyClass(same, "pdbase");
    testCase.verifyEqual(same.LocalValues, vals);
    testCase.verifyEqual(once.LocalValues{1}, {0, 0.5, 1});
    testCase.verifyEqual(once.LocalValues{2}, {2, 3, 4});
    testCase.verifyEqual(twice.LocalValues{1}, ...
        {0, 1 / 3, 2 / 3, 1}, AbsTol=1e-14);
    testCase.verifyEqual(twice.LocalValues{2}, ...
        {2, 8 / 3, 10 / 3, 4}, AbsTol=1e-14);
    testCase.verifyEqual(obj.LocalValues, before);
    testCase.verifyEqual(obj.Degree, 1);
end

function test_tensor_elevation_package_wide_coefficient_row(testCase)
    % Tensor elevation must retain the package-wide coefficient row order.
    vals = {{{0, 2, 4, 6}}};
    obj = pdbase({[0 1], [10 20]}, [1 1], 1, vals);

    out = obj.elevate(1);

    expected = {0, 1, 2, 2, 3, 4, 4, 5, 6};
    testCase.verifyEqual(out.LocalValues{1}{1}, expected);
    testCase.verifyEqual(size(out.LocalValues{1}{1}), [1 9]);
end

function test_rate_rows_elevated_without_reordering_or(testCase)
    % Rate rows must be elevated without reordering or mixing.
    vals = {{0, 2; 10, 14}};
    obj = pdbase({[0 1]}, [1 1], 1, vals, ...
        RateBounds=[-1 1]);

    out = obj.elevate(1);

    testCase.verifyEqual(out.LocalValues{1}, {0, 1, 2; 10, 12, 14});
    testCase.verifyEqual(size(out.LocalValues{1}), [2 3]);
    testCase.verifyEqual(obj.LocalValues, vals);
    testCase.verifyEqual(obj.RateBounds, [-1 1]);
end

function test_invalid_increments_fail_transforming_coefficient(testCase)
    % Invalid increments must fail before transforming the coefficient tree.
    obj = pdbase({[0 1]}, [1 1], 1, {{0, 1}});

    bad = {-1, 0.5, Inf, NaN, "one", [1 2]};
    for k = 1:numel(bad)
        testCase.verifyError(@() obj.elevate(bad{k}), ...
            "pdbase:InvalidDegreeIncrement");
    end
end

function test_call_local_validation_mode_scalar_text(testCase)
    % The call-local validation mode remains scalar text owned by pdbase.
    obj = pdbase({[0 1], [10 20]}, [1 1], [1 0], {{{1, 2}}});
    bad = {42, ["fast", "strict"], string(missing), '', "sample"};

    for k = 1:numel(bad)
        testCase.verifyError(@() obj.elevate([0 1], bad{k}), ...
            "pdbase:InvalidValidationMode");
    end
end

function test_value_class_copy_changes_basis_while(testCase)
    % A value-class copy changes basis while retaining the source object.
    vals = {{{0, 2, 4, 6}}};
    obj = pdbase({[0 1], [10 20]}, [1 1], 1, vals);

    same = obj.elevate(0);
    out = obj.elevate(1);

    testCase.verifyClass(same, "pdbase");
    testCase.verifyEqual(same.Degree, [1 1]);
    testCase.verifyEqual(same.LocalValues, vals);
    testCase.verifyClass(out, "pdbase");
    testCase.verifyEqual(out.Degree, [2 2]);
    pts = [0 10; 0.25 14; 1 20];
    for k = 1:size(pts, 1)
        testCase.verifyEqual(out.evaluate(pts(k, :)), ...
            obj.evaluate(pts(k, :)), AbsTol=1e-12);
    end
    testCase.verifyEqual(obj.Degree, [1 1]);
    testCase.verifyEqual(obj.LocalValues, vals);
end

function test_rate_vertex_same_map_without_mixing(testCase)
    % Every rate vertex uses the same map without mixing coefficient rows.
    nParameters = 2;
    sourceDegree = 1;
    targetDegree = 3;
    sourceCount = (sourceDegree + 1) ^ nParameters;
    leaf = cell(2 ^ nParameters, sourceCount);
    for row = 1:size(leaf, 1)
        for coefficient = 1:size(leaf, 2)
            leaf{row, coefficient} = 100 * row + coefficient;
        end
    end
    values = helper.mkNest([1 1], @(~) leaf);
    obj = pdbase({[0 1], [10 20]}, [1 1], sourceDegree, values, ...
        RateBounds=[-1 1; -2 3]);

    elevated = obj.elevate(targetDegree - sourceDegree);
    actual = elevated.coeffs([1 1]);

    testCase.verifySize(actual, [4, 16]);
    for row = 1:size(leaf, 1)
        expected = legacyElevate(leaf(row, :), ...
            sourceDegree, targetDegree, nParameters);
        verifyCoefficientRow(testCase, actual(row, :), expected, 1e-13);
    end
end

function out = legacyElevate(source, sourceDegree, targetDegree, nParameters)
    % Direct source-to-target incidence oracle for Bernstein elevation.
    sourceDegree = expandDegree(sourceDegree, nParameters);
    targetDegree = expandDegree(targetDegree, nParameters);
    sourceLabels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, ...
        sourceDegree, "UniformOutput", false));
    targetLabels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, ...
        targetDegree, "UniformOutput", false));
    gap = targetDegree - sourceDegree;
    out = cell(1, size(targetLabels, 1));
    for targetIndex = 1:size(targetLabels, 1)
        targetLabel = targetLabels(targetIndex, :);
        accumulator = [];
        for sourceIndex = 1:size(sourceLabels, 1)
            sourceLabel = sourceLabels(sourceIndex, :);
            delta = targetLabel - sourceLabel;
            if any(delta < 0) || any(delta > gap)
                continue
            end
            scale = 1;
            for parameter = 1:nParameters
                scale = scale ...
                    * nchoosek(sourceDegree(parameter), sourceLabel(parameter)) ...
                    * nchoosek(gap(parameter), delta(parameter)) ...
                    / nchoosek(targetDegree(parameter), targetLabel(parameter));
            end
            term = source{sourceIndex} .* scale;
            if isempty(accumulator)
                accumulator = term;
            else
                accumulator = accumulator + term;
            end
        end
        out{targetIndex} = accumulator;
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

function degree = expandDegree(degree, nParameters)
    % Expand scalar shorthand without sharing production normalizer logic.
    degree = reshape(degree, 1, []);
    if isscalar(degree)
        degree = repmat(degree, 1, nParameters);
    end
end

function test_binomial_reference_all_rows(testCase)
    for rates = [false true]
        A = tests.infrastructure.fixture("pdbase", rates);
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
end

function test_object_api_rejects_negative_increment(testCase)
    % Dot-call syntax must retain the degree validation contract.
    obj = pdbase({[0 1]}, [1 1], 1, {{0, 1}});
    testCase.verifyError(@() obj.elevate(-1), "pdbase:InvalidDegreeIncrement");
end

function test_constant_tensor_incidence(testCase)
    % Independent incidence weights preserve each constant matrix entry.
    grid = {[0 1], [10 20], [-1 1]};
    matrix = [1 2; 3 5];
    values = helper.mkNest([1 1 1], @(~) {matrix});
    source = pdbase(grid, [2 2], 0, values);
    actual = source.elevate(3);
    expected = tests.infrastructure.elevate({matrix}, [0 0 0], [3 3 3]);
    verifyCoefficientRow(testCase, actual.coeffs([1 1 1]), expected, 1e-13);
end
