function tests = test_public_names
    %TEST_PUBLIC_NAMES Public pd* identities and breaking rename contract.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep comparison construction independent of prior YALMIP decisions.
    yalmip("clear");
end

function testPubClaIde(testCase)
    % Every public type should use the pd* name and shared pdbase parent.
    base = pdbase({[0 1]}, [1 1], 0);
    known = pdmat({[0 1]}, {1, 2}, Degree=1);
    decision = pdvar(1, {[0 1]}, Degree=0);
    comparison = decision >= 0;

    testCase.verifyClass(base, "pdbase");
    testCase.verifyClass(known, "pdmat");
    testCase.verifyClass(decision, "pdvar");
    testCase.verifyClass(comparison, "pdlmi");
    testCase.verifyTrue(isa(known, "pdbase"));
    testCase.verifyTrue(isa(decision, "pdbase"));
    testCase.verifyEqual(base.NumRateRows, 0);
    testCase.verifyEqual(known.NumRateRows, 0);
    testCase.verifyEqual(decision.NumRateRows, 0);
end

function testLegClaNamAreAbs(testCase)
    % The breaking rename intentionally provides no compatibility aliases.
    legacyNames = ["dpbase", "dpmat", "dpvar", "dplmi"];
    for name = legacyNames
        testCase.verifyEmpty(which(name));
        testCase.verifyEmpty(which(name, "-all"));
    end
end

function testPubErrUsePdPre(testCase)
    % Representative failures should expose the renamed public namespaces.
    P = pdvar(1, {[0 1]}, Degree=0);

    testCase.verifyError(@() pdbase({[0 1]}, [1 1], -1), ...
        "pdbase:InvalidDegree");
    testCase.verifyError(@() pdmat({[0 1]}, eye(2)), ...
        "pdmat:InvalidSource");
    testCase.verifyError(@() pdvar(1, {[0 1]}, Degree=-1), ...
        "pdvar:InvalidDegree");
    testCase.verifyError(@() pdlmi(P, "="), ...
        "pdlmi:InvalidRelation");
end

function testApiRenames(testCase)
    % Breaking replacements exist while every superseded method stays absent.
    base = pdbase({[0 1]}, [1 1], 0, {{1}});
    known = pdmat({[0 1]}, {1}, Degree=0);
    decision = pdvar(1, {[0 1]}, Degree=0);
    wrapper = decision >= 0;

    testCase.verifyTrue(ismethod(base, "elevate"));
    testCase.verifyFalse(ismethod(base, "elevVals"));
    testCase.verifyFalse(ismethod(base, "hasRateRows"));
    testCase.verifyTrue(isprop(base, "NumRateRows"));
    testCase.verifyFalse(isprop(base, "HasRateRows"));
    testCase.verifyTrue(ismethod(known, "bernTable"));
    testCase.verifyTrue(ismethod(decision, "bernTable"));
    testCase.verifyFalse(ismethod(known, "bernsteinTable"));
    testCase.verifyFalse(ismethod(decision, "bernsteinTable"));

    current = ["usePolya", "usePutinar", "useFullBox", ...
        "useSpPut", "useSpBox"];
    removed = ["applyPolya", "applyPutinar", "applyFullBoxPreorder", ...
        "applySparsePutinar", "applySparseFullBoxPreorder"];
    for name = current
        testCase.verifyTrue(ismethod(wrapper, name), ...
            "Missing replacement pdlmi method: " + name);
    end
    for name = removed
        testCase.verifyFalse(ismethod(wrapper, name), ...
            "Removed pdlmi method remains available: " + name);
    end

    testCase.verifyNotEmpty(which("helper.normDeg"));
    testCase.verifyEmpty(which("helper.normalizeDegree"));
end
