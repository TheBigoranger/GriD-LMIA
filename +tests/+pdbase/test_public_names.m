function tests = test_public_names
    %TEST_PUBLIC_NAMES Public pd* identities and breaking rename contract.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep comparison construction independent of prior YALMIP decisions.
    yalmip("clear");
end

function testPublicClassIdentities(testCase)
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
end

function testLegacyClassNamesAreAbsent(testCase)
    % The breaking rename intentionally provides no compatibility aliases.
    legacyNames = ["dpbase", "dpmat", "dpvar", "dplmi"];
    for name = legacyNames
        testCase.verifyEmpty(which(name));
        testCase.verifyEmpty(which(name, "-all"));
    end
end

function testPublicErrorsUsePdPrefixes(testCase)
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
