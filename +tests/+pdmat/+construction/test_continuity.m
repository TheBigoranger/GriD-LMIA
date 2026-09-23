function tests = test_continuity
    % Direction-wise continuity inference and verification for pdmat.
    tests = functiontests(localfunctions);
end

function test_automatic_classification_and_explicit_weaker_bounds(testCase)
    grid = {[0 1 3]};
    c2 = {{0, 1, 3, 6}, {6, 12, 22, 40}};
    c1 = c2;
    c1{2}{3} = 21;
    c0 = c1;
    c0{2}{2} = 11;
    broken = c0;
    broken{2}{1} = 7;
    cinf = {{0, 0, 1/3, 1}, {1, 7/3, 5, 9}};

    testCase.verifyEqual(pdmat(grid, c2, Degree=3).Continuity, 2);
    testCase.verifyEqual(pdmat(grid, c1, Degree=3).Continuity, 1);
    testCase.verifyEqual(pdmat(grid, c0, Degree=3).Continuity, 0);
    testCase.verifyEqual(withWarningOff(@() pdmat(grid, broken, Degree=3)).Continuity, -1);
    testCase.verifyEqual(pdmat(grid, cinf, Degree=3).Continuity, Inf);

    weaker = pdmat(grid, c2, Degree=3, Continuity=1);
    exact = pdmat(grid, c2, Degree=3, Continuity=2);
    testCase.verifyEqual(weaker.Continuity, 1);
    testCase.verifyEqual(exact.Continuity, 2);
    testCase.verifyError(@() pdmat(grid, c2, Degree=3, Continuity=3), ...
        "pdmat:ContinuityMismatch");
end

function test_function_sources_scalar_warning_and_invalid_requests(testCase)
    grid = {[0 1 2], [10 20 30]};
    functionOnly = pdmat(grid, @(x, y) x + y);
    certified = pdmat(grid, @(x, y) x.^2 + y, Degree=[2 1]);

    testCase.verifyEqual(functionOnly.Continuity, [-1 -1]);
    testCase.verifyFalse(functionOnly.IsContinuous);
    testCase.verifyEqual(certified.Continuity, [Inf Inf]);
    testCase.verifyError(@() pdmat(grid, @(x, y) x+y, Continuity=0), ...
        "pdmat:FunctionOnlyContinuity");
    testCase.verifyWarning(@() pdmat(grid, repmat({0}, 3, 3), ...
        Degree=[1 1], Continuity=0), ...
        "pdmat:ScalarContinuityExpansion");

    bad = {[], -1, [0 -1], [0 1 2], [0.5 1], [NaN 0], "C1"};
    data = repmat({0}, 3, 3);
    for k = 1:numel(bad)
        testCase.verifyError(@() pdmat(grid, data, Degree=[1 1], ...
            Continuity=bad{k}), "pdmat:InvalidContinuity");
    end
end

function test_late_matrix_rate_row_and_tolerance_evidence(testCase)
    z = zeros(2);
    eye2 = eye(2);
    values = {
        {z, eye2, 2*eye2; 10+z, 10+eye2, 10+2*eye2}, ...
        {2*eye2, 3*eye2, 4*eye2; 10+2*eye2, 10+3*eye2, 10+4*eye2}, ...
        {4*eye2, 5*eye2, 6*eye2; 10+4*eye2, 10+5*eye2, 10+6*eye2}
        };
    values{3}{2, 2}(2, 2) = values{3}{2, 2}(2, 2) + 1;
    late = pdmat([0 1 2 3], values, Degree=2, RateBounds=[-1 1]);
    testCase.verifyEqual(late.Continuity, 0);

    within = {{0, 1}, {1, 3 + 1e-10}};
    outside = {{0, 1}, {1, 3 + 1e-6}};
    testCase.verifyEqual(pdmat([0 1 3], within, Degree=1).Continuity, Inf);
    testCase.verifyEqual(pdmat([0 1 3], outside, Degree=1).Continuity, 0);
end

function out = withWarningOff(fcn)
    state = warning("query", "pdmat:DiscontinuousLocalValues");
    cleanup = onCleanup(@() warning(state)); %#ok<NASGU>
    warning("off", "pdmat:DiscontinuousLocalValues");
    out = fcn();
end
