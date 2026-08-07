function tests = test_validation_mode
    %TEST_VALIDATION_MODE Public pdmat validation remains complete in fast mode.
    tests = functiontests(localfunctions);
end

function testModPreValKnoDat(testCase)
    % Mode selection is transient and leaves the represented data unchanged.
    grid = [0 1 2];
    vals = {{1, 2}, {2, 3}};

    implicit = pdmat(grid, vals, Degree=1);
    fast = pdmat(grid, vals, Degree=1, ValidationMode="FAST");
    strict = pdmat(grid, vals, Degree=1, ValidationMode='Strict');

    testCase.verifyTrue(isequal(implicit, fast));
    testCase.verifyTrue(isequal(fast, strict));
    testCase.verifyFalse(isprop(implicit, "ValidationMode"));
end

function testFasStiValEvePub(testCase)
    % Source normalization must reject malformed later cells in both modes.
    grid = [0 1 2];
    badPayload = {{1, 2}, {3, "bad"}};
    badCount = {{1, 2}, {3}};
    for mode = ["fast", "strict"]
        testCase.verifyError(@() pdmat(grid, badPayload, Degree=1, ...
            ValidationMode=mode), "pdmat:InvalidCoefficientPayload");
        testCase.verifyError(@() pdmat(grid, badCount, Degree=1, ...
            ValidationMode=mode), "pdmat:InvalidLocalValues");
    end
end

function testInvModUseOwnIde(testCase)
    % pdmat owns all ValidationMode diagnostics at its public boundary.
    make = @(mode) pdmat([0 1], {1}, Degree=0, ...
        ValidationMode=mode);
    bad = {42, ["fast", "strict"], string(missing), '', "sample"};
    for k = 1:numel(bad)
        testCase.verifyError(@() make(bad{k}), ...
            "pdmat:InvalidValidationMode");
    end
    testCase.verifyError(@() pdmat([0 1], {1}, ...
        "ValidationMode"), "pdmat:InvalidValidationMode");
end

function testConIsRecWheAlg(testCase)
    % Slicing away the only discontinuous entry restores exact continuity.
    vals = { ...
        {[1 0; 0 0], [1 0; 0 0]}, ...
        {[1 0; 1 0], [1 0; 1 0]}};
    A = suppDisWar(@() pdmat([0 1 2], vals, Degree=1));
    slice = A(1, :);
    cancelled = A - A;

    testCase.verifyFalse(A.IsContinuous);
    testCase.verifyTrue(slice.IsContinuous);
    testCase.verifyTrue(cancelled.IsContinuous);
end

function out = suppDisWar(fun)
    % Build the intended discontinuous fixture without polluting test output.
    id = "pdmat:DiscontinuousLocalValues";
    state = warning("query", id);
    cleanup = onCleanup(@() warning(state.state, id)); %#ok<NASGU>
    warning("off", id);
    out = fun();
end
