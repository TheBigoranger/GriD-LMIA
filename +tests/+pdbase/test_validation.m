function tests = test_validation
    %TEST_VALIDATION Public constructor rejects malformed inputs clearly.
    tests = functiontests(localfunctions);
end

function testBadGridShape(testCase)
    % Grid input should be a nonempty cell array of grid vectors.
    testCase.verifyError(@() pdbase([0 1], [1 1], 0), "pdbase:InvalidGrid");
    testCase.verifyError(@() pdbase({}, [1 1], 0), "pdbase:InvalidGrid");
end

function testBadGridNodes(testCase)
    % Grid vectors should be finite, strictly increasing numeric nodes.
    testCase.verifyError(@() pdbase({[0 1 1]}, [1 1], 0), "pdbase:InvalidGridVector");
    testCase.verifyError(@() pdbase({[0 2 1]}, [1 1], 0), "pdbase:InvalidGridVector");
    testCase.verifyError(@() pdbase({[0 Inf]}, [1 1], 0), "pdbase:InvalidGridVector");
    testCase.verifyError(@() pdbase({[0 NaN]}, [1 1], 0), "pdbase:InvalidGridVector");
end

function testBadDeg(testCase)
    % Degree should be a finite nonnegative integer.
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], -1), "pdbase:InvalidDegree");
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 1.5), "pdbase:InvalidDegree");
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], Inf), "pdbase:InvalidDegree");
end

function testBadSize(testCase)
    % MatrixSize should be a positive 2-D integer size vector.
    testCase.verifyError(@() pdbase({[0 1]}, [1 0], 0), "pdbase:InvalidMatrixSize");
    testCase.verifyError(@() pdbase({[0 1]}, [1 1 1], 0), "pdbase:InvalidMatrixSize");
    testCase.verifyError(@() pdbase({[0 1]}, [1.5 1], 0), "pdbase:InvalidMatrixSize");
end

function testBadRateBounds(testCase)
    % RateBounds should match parameter count and contain finite lower/upper pairs.
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, [], RateBounds=[0 1; -1 1]), ...
        "pdbase:InvalidRateBounds");
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, [], RateBounds=[1 -1]), ...
        "pdbase:InvalidRateBounds");
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, [], RateBounds=[0 Inf]), ...
        "pdbase:InvalidRateBounds");
end

function testBadCoeffCount(testCase)
    % LocalValues should fail for missing cells or wrong coefficient counts.
    testCase.verifyError(@() pdbase({[0 1 2]}, [1 1], 1, {{1, 2}}), ...
        "pdbase:InvalidLocalValues");
    testCase.verifyError(@() pdbase({[0 1 2]}, [1 1], 1, {{1}, {2, 3}}), ...
        "pdbase:InvalidCoefficientCell");
end

function testBadPlainPayload(testCase)
    % Plain payloads must stay finite real numeric matrices at pdbase level.
    invalidPayloads = { ...
        [1 NaN; 0 1], ...
        [1 Inf; 0 1], ...
        [1 1i; 0 1], ...
        ['a' 'b'; 'c' 'd'], ...
        {1 2; 3 4}, ...
        repmat(struct("Constant", 0), 2, 2)};

    for k = 1:numel(invalidPayloads)
        testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, ...
            scalarVals(invalidPayloads{k})), "pdbase:InvalidCoefficientPayload");
    end
end

function testSymbolicPayloadOk(testCase)
    % pdbase storage accepts real 2-D YALMIP payloads for pdvar subclasses.
    X = sdpvar(2, 2, 'full');

    obj = pdbase({[0 1]}, [2 2], 0, scalarVals(X), ...
        ContainsDecision=true);

    coeffs = obj.coeffs(1);
    testCase.verifyTrue(isa(coeffs{1}, "sdpvar"));
    testCase.verifyEqual(size(coeffs{1}), [2 2]);
    testCase.verifyTrue(obj.ContainsDecision);
end

function testRatePayloadOk(testCase)
    % Rate-affine payload structs should preserve constant and rate parts.
    payload = ratePayload(2);
    rb = [-1 1; -2 2];

    obj = pdbase({[0 1], [10 20]}, [2 2], 0, tensorVals(payload), ...
        RateBounds=rb);

    coeffs = obj.coeffs([1 1]);
    testCase.verifyTrue(obj.HasRateDependence);
    testCase.verifyEqual(obj.RateBounds, rb);
    testCase.verifyEqual(coeffs{1}.Constant, payload.Constant);
    testCase.verifyEqual(coeffs{1}.Rate, payload.Rate);
end

function testBadRatePayload(testCase)
    % Malformed rate-affine structs should fail payload validation.
    payload = ratePayload(1);

    nonCellRate = payload;
    nonCellRate.Rate = zeros(2);
    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, ...
        scalarVals(nonCellRate), RateBounds=[-1 1]), ...
        "pdbase:InvalidCoefficientPayload");

    wrongRateLength = payload;
    wrongRateLength.Rate = {zeros(2), zeros(2)};
    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, ...
        scalarVals(wrongRateLength), RateBounds=[-1 1]), ...
        "pdbase:InvalidCoefficientPayload");

    invalidConstant = payload;
    invalidConstant.Constant = [1 NaN; 0 1];
    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, ...
        scalarVals(invalidConstant), RateBounds=[-1 1]), ...
        "pdbase:InvalidCoefficientPayload");

    invalidRateEntry = payload;
    invalidRateEntry.Rate{1} = [1 Inf; 0 1];
    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, ...
        scalarVals(invalidRateEntry), RateBounds=[-1 1]), ...
        "pdbase:InvalidCoefficientPayload");
end

function testRateNeedsBounds(testCase)
    % Rate-affine payloads should require explicit RateBounds.
    payload = ratePayload(1);

    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, scalarVals(payload)), ...
        "pdbase:InvalidRateBounds");
    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, scalarVals(payload), ...
        RateBounds=[]), "pdbase:InvalidRateBounds");
end

function testFlagNeedsBounds(testCase)
    % Explicit HasRateDependence should also require RateBounds.
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, [], HasRateDependence=true), ...
        "pdbase:InvalidRateBounds");
end

function testBoundsSetRateFlag(testCase)
    % Supplying RateBounds should mark the object as rate-dependent.
    obj = pdbase({[0 1]}, [1 1], 0, [], RateBounds=[-1 1]);

    testCase.verifyTrue(obj.HasRateDependence);
    testCase.verifyEqual(obj.RateBounds, [-1 1]);
end

function localValues = scalarVals(payload)
    % Scalar grids still store one flat coefficient cell inside LocalValues.
    localValues = {{payload}};
end

function localValues = tensorVals(payload)
    % Tensor grids use nested physical-cell storage even for a single cell.
    localValues = {{{payload}}};
end

function payload = ratePayload(nPar)
    % Build a valid rate-affine payload with one rate matrix per parameter.
    payload = struct("Constant", eye(2), "Rate", {cell(1, nPar)});
    for k = 1:nPar
        payload.Rate{k} = k * ones(2);
    end
end
