function verify_transform(testCase, owner, transform, reference)
    %VERIFY_TRANSFORM Compare every payload with its native matrix operation.
    if nargin < 4, reference = transform; end
    for rates = [false true]
        source = tests.infrastructure.fixture(owner, rates);
        saved = source.LocalValues;
        actual = transform(source);
        for cellIndex = 1:2
            input = source.coeffs(cellIndex);
            expected = cellfun(reference, input, 'UniformOutput', false);
            tests.infrastructure.verify_expr(testCase, actual.coeffs(cellIndex), expected);
        end
        testCase.verifyEqual(source.LocalValues, saved);
        testCase.verifyEqual(actual.Degree, source.Degree);
        testCase.verifyEqual(actual.RateBounds, source.RateBounds);
        testCase.verifyEqual(actual.NumRateRows, source.NumRateRows);
        testCase.verifyEqual(actual.ContainsDecision, source.ContainsDecision);
        testCase.verifyClass(actual, owner);
    end
end
