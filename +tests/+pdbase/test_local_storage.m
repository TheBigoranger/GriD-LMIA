function tests = test_local_storage
    %TEST_LOCAL_STORAGE Nested LocalValues access and validation.
    tests = functiontests(localfunctions);
end

function testScalarFlat(testCase)
    % Scalar grids should expose flat per-cell coefficient storage.
    localValues = {{11, 12, 13}, {21, 22, 23}};
    obj = pdbase({[0 1 2]}, [1 1], 2, localValues);

    % A scalar grid still stores one flat coefficient cell per physical cell.
    testCase.verifyEqual(obj.LocalValues{1}, {11, 12, 13});
    testCase.verifyEqual(obj.coeffs(2), {21, 22, 23});
    testCase.verifyEqual(obj.coeffs({1}), {11, 12, 13});
    testCase.verifyEqual(obj.ncoeff(), 3);
end

function testTensorNest(testCase)
    % Tensor grids should preserve nested physical-cell access.
    localValues = {
        {mkCoeff(110), mkCoeff(120)}, ...
        {mkCoeff(210), mkCoeff(220)}
        };
    obj = pdbase({[0 1 2], [10 20 30]}, [1 1], 1, localValues);

    testCase.verifyEqual(obj.LocalValues{2}{1}, mkCoeff(210));
    testCase.verifyEqual(obj.coeffs([1 2]), mkCoeff(120));
    testCase.verifyEqual(obj.coeffs({2, 2}), mkCoeff(220));
    testCase.verifyEqual(obj.ncoeff(), 4);
end

function testRateOutside(testCase)
    % Rate bounds should live on the object, not inside LocalValues.
    obj = pdbase({[0 1], [10 20]}, [1 1], 0, [], ...
        RateBounds=[-1 1; -2 2]);

    coeffs = obj.coeffs([1 1]);
    testCase.verifyEqual(obj.RateBounds, [-1 1; -2 2]);
    testCase.verifyEqual(numel(coeffs), 1);
    testCase.verifyEqual(coeffs{1}, 0);
end

function testBadNest(testCase)
    % Tensor LocalValues must be nested by physical cell dimensions.
    flatCells = {mkCoeff(11), mkCoeff(12), mkCoeff(21), mkCoeff(22)};

    testCase.verifyError(@() pdbase({[0 1 2], [10 20 30]}, [1 1], 1, flatCells), ...
        "pdbase:InvalidLocalValues");
end

function testBadCoeffCount(testCase)
    % Each physical cell must contain exactly ncoeff local coefficients.
    badValues = {{1}, {2, 3}};

    testCase.verifyError(@() pdbase({[0 1 2]}, [1 1], 1, badValues), ...
        "pdbase:InvalidCoefficientCell");
end

function testBadCellSubs(testCase)
    % coeffs should reject out-of-range, wrong-width, or noninteger subscripts.
    obj = pdbase({[0 1 2], [10 20]}, [1 1], 0);

    testCase.verifyError(@() obj.coeffs([0 1]), "pdbase:InvalidCellSubs");
    testCase.verifyError(@() obj.coeffs([3 1]), "pdbase:InvalidCellSubs");
    testCase.verifyError(@() obj.coeffs([1]), "pdbase:InvalidCellSubs");
    testCase.verifyError(@() obj.coeffs([1 1.5]), "pdbase:InvalidCellSubs");
    testCase.verifyError(@() obj.coeffs({1, 1, 1}), "pdbase:InvalidCellSubs");
end

function c = mkCoeff(offset)
    % Keep tensor-cell payloads visually distinct while preserving flat order.
    c = {offset + 1, offset + 2, offset + 3, offset + 4};
end
