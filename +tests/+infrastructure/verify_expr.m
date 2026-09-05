function verify_expr(testCase, actual, expected)
    %VERIFY_EXPR Compare affine expressions, including variable identity.
    testCase.assertSize(actual, size(expected));
    if iscell(actual)
        for k = 1:numel(actual)
            tests.infrastructure.verify_expr(testCase, actual{k}, expected{k});
        end
        return
    end
    difference = actual - expected;
    if isa(difference, 'sdpvar'), difference = full(getbase(difference)); end
    testCase.verifyLessThanOrEqual(norm(difference, 'fro'), 1e-10);
end
