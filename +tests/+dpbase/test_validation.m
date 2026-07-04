function tests = test_validation
    %TEST_VALIDATION Public constructor rejects malformed inputs clearly.
    tests = functiontests(localfunctions);
end

function testBadGridShape(testCase)
    testCase.verifyError(@() dpbase([0 1], [1 1], 0), "dpbase:InvalidGrid");
    testCase.verifyError(@() dpbase({}, [1 1], 0), "dpbase:InvalidGrid");
end

function testBadGridNodes(testCase)
    testCase.verifyError(@() dpbase({[0 1 1]}, [1 1], 0), "dpbase:InvalidGridVector");
    testCase.verifyError(@() dpbase({[0 2 1]}, [1 1], 0), "dpbase:InvalidGridVector");
    testCase.verifyError(@() dpbase({[0 Inf]}, [1 1], 0), "dpbase:InvalidGridVector");
    testCase.verifyError(@() dpbase({[0 NaN]}, [1 1], 0), "dpbase:InvalidGridVector");
end

function testBadDeg(testCase)
    testCase.verifyError(@() dpbase({[0 1]}, [1 1], -1), "dpbase:InvalidDegree");
    testCase.verifyError(@() dpbase({[0 1]}, [1 1], 1.5), "dpbase:InvalidDegree");
    testCase.verifyError(@() dpbase({[0 1]}, [1 1], Inf), "dpbase:InvalidDegree");
end

function testBadSize(testCase)
    testCase.verifyError(@() dpbase({[0 1]}, [1 0], 0), "dpbase:InvalidMatrixSize");
    testCase.verifyError(@() dpbase({[0 1]}, [1 1 1], 0), "dpbase:InvalidMatrixSize");
    testCase.verifyError(@() dpbase({[0 1]}, [1.5 1], 0), "dpbase:InvalidMatrixSize");
end

function testBadRateBounds(testCase)
    testCase.verifyError(@() dpbase({[0 1]}, [1 1], 0, [], RateBounds=[0 1; -1 1]), ...
        "dpbase:InvalidRateBounds");
    testCase.verifyError(@() dpbase({[0 1]}, [1 1], 0, [], RateBounds=[1 -1]), ...
        "dpbase:InvalidRateBounds");
    testCase.verifyError(@() dpbase({[0 1]}, [1 1], 0, [], RateBounds=[0 Inf]), ...
        "dpbase:InvalidRateBounds");
end

function testBadCoeffCount(testCase)
    testCase.verifyError(@() dpbase({[0 1 2]}, [1 1], 1, {{1, 2}}), ...
        "dpbase:InvalidLocalValues");
    testCase.verifyError(@() dpbase({[0 1 2]}, [1 1], 1, {{1}, {2, 3}}), ...
        "dpbase:InvalidCoefficientCell");
end

function testBadPlainPayload(testCase)
    % Plain payloads must stay finite real numeric matrices at dpbase level.
    invalidPayloads = { ...
        [1 NaN; 0 1], ...
        [1 Inf; 0 1], ...
        [1 1i; 0 1], ...
        ['a' 'b'; 'c' 'd'], ...
        {1 2; 3 4}, ...
        repmat(struct("Constant", 0), 2, 2)};

    for k = 1:numel(invalidPayloads)
        testCase.verifyError(@() dpbase({[0 1]}, [2 2], 0, ...
            scalarVals(invalidPayloads{k})), "dpbase:InvalidCoefficientPayload");
    end
end

function testRatePayloadOk(testCase)
    payload = ratePayload(2);
    rb = [-1 1; -2 2];

    obj = dpbase({[0 1], [10 20]}, [2 2], 0, tensorVals(payload), ...
        RateBounds=rb);

    coeffs = obj.coeffs([1 1]);
    testCase.verifyTrue(obj.HasRateDependence);
    testCase.verifyEqual(obj.RateBounds, rb);
    testCase.verifyEqual(coeffs{1}.Constant, payload.Constant);
    testCase.verifyEqual(coeffs{1}.Rate, payload.Rate);
end

function testBadRatePayload(testCase)
    payload = ratePayload(1);

    nonCellRate = payload;
    nonCellRate.Rate = zeros(2);
    testCase.verifyError(@() dpbase({[0 1]}, [2 2], 0, ...
        scalarVals(nonCellRate), RateBounds=[-1 1]), ...
        "dpbase:InvalidCoefficientPayload");

    wrongRateLength = payload;
    wrongRateLength.Rate = {zeros(2), zeros(2)};
    testCase.verifyError(@() dpbase({[0 1]}, [2 2], 0, ...
        scalarVals(wrongRateLength), RateBounds=[-1 1]), ...
        "dpbase:InvalidCoefficientPayload");

    invalidConstant = payload;
    invalidConstant.Constant = [1 NaN; 0 1];
    testCase.verifyError(@() dpbase({[0 1]}, [2 2], 0, ...
        scalarVals(invalidConstant), RateBounds=[-1 1]), ...
        "dpbase:InvalidCoefficientPayload");

    invalidRateEntry = payload;
    invalidRateEntry.Rate{1} = [1 Inf; 0 1];
    testCase.verifyError(@() dpbase({[0 1]}, [2 2], 0, ...
        scalarVals(invalidRateEntry), RateBounds=[-1 1]), ...
        "dpbase:InvalidCoefficientPayload");
end

function testRateNeedsBounds(testCase)
    payload = ratePayload(1);

    testCase.verifyError(@() dpbase({[0 1]}, [2 2], 0, scalarVals(payload)), ...
        "dpbase:InvalidRateBounds");
    testCase.verifyError(@() dpbase({[0 1]}, [2 2], 0, scalarVals(payload), ...
        RateBounds=[]), "dpbase:InvalidRateBounds");
end

function testFlagNeedsBounds(testCase)
    testCase.verifyError(@() dpbase({[0 1]}, [1 1], 0, [], HasRateDependence=true), ...
        "dpbase:InvalidRateBounds");
end

function testBoundsSetRateFlag(testCase)
    obj = dpbase({[0 1]}, [1 1], 0, [], RateBounds=[-1 1]);

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
    payload = struct("Constant", eye(2), "Rate", {cell(1, nPar)});
    for k = 1:nPar
        payload.Rate{k} = k * ones(2);
    end
end
