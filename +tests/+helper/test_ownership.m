function tests = test_ownership
    %TEST_OWNERSHIP Lock the shared-helper namespace to cross-class utilities.
    tests = functiontests(localfunctions);
end

function testApprovedHelperSetAndConsumers(testCase)
    % Shared helpers must be both approved and consumed by multiple classes.
    root = repositoryRoot();
    files = dir(fullfile(root, "+helper", "*.m"));
    actual = sort(string(erase({files.name}, ".m")));
    approved = sort(["cellGet", "chk", "combRows", "isZero", ...
        "mkGrid", "mkNest", "normalizeDegree"]);

    testCase.verifyEqual(actual, approved, ...
        "The +helper namespace must contain exactly the approved shared utilities.");

    classes = ["pdbase", "pdmat", "pdvar", "pdlmi"];
    for helperName = approved
        consumers = strings(0, 1);
        needle = "helper\." + helperName + "\s*\(";
        for className = classes
            sources = dir(fullfile(root, "@" + className, "**", "*.m"));
            used = false;
            for source = reshape(sources, 1, [])
                text = fileread(fullfile(source.folder, source.name));
                if ~isempty(regexp(text, needle, "once")) %#ok<RGXP1>
                    used = true;
                    break
                end
            end
            if used
                consumers(end + 1, 1) = className; %#ok<AGROW>
            end
        end
        testCase.verifyGreaterThanOrEqual(numel(consumers), 2, ...
            "helper." + helperName + " has fewer than two package-class consumers.");
    end
end

function testPdbaseInternalUtilityOwnership(testCase)
    % Object-aware table, mapping, and indexing mechanics belong to pdbase.
    root = repositoryRoot();
    names = ["bernTbl", "mapVals", "matSubs"];

    for name = names
        testCase.verifyTrue(isfile(fullfile(root, "@pdbase", name + ".m")), ...
            "Missing pdbase-owned internal utility: " + name);
        testCase.verifyFalse(isfile(fullfile(root, "+helper", name + ".m")), ...
            "pdbase-owned internal utilities must not remain in +helper: " + name);
    end
end

function testSharedMatrixOperationOwnership(testCase)
    % Common public wrappers belong only to pdbase; subclasses inherit them.
    root = repositoryRoot();
    names = ["uminus", "transpose", "ctranspose", "trace", "vec", ...
        "diag", "tril", "triu", "flip", "fliplr", "flipud", "rot90", ...
        "reshape", "repmat", "sum", "mean", "cumsum"];

    for name = names
        testCase.verifyTrue(isfile(fullfile(root, "@pdbase", name + ".m")), ...
            "Missing pdbase-owned operation: " + name);
        testCase.verifyFalse(isfile(fullfile(root, "@pdmat", name + ".m")), ...
            "pdmat must inherit the shared operation: " + name);
        testCase.verifyFalse(isfile(fullfile(root, "@pdvar", name + ".m")), ...
            "pdvar must inherit the shared operation: " + name);
    end

    testCase.verifyFalse(isfile(fullfile(root, "@pdmat", "private", "unOp.m")));
    testCase.verifyFalse(isfile(fullfile(root, "@pdvar", "private", "unOp.m")));
    testCase.verifyTrue(isfile(fullfile(root, "@pdbase", "unOp.m")));
    testCase.verifyTrue(isfile(fullfile(root, "@pdbase", "mkUnOp.m")));
    testCase.verifyTrue(isfile(fullfile(root, "@pdmat", "mkUnOp.m")));
    testCase.verifyTrue(isfile(fullfile(root, "@pdvar", "mkUnOp.m")));
end

function root = repositoryRoot()
    helperTests = fileparts(mfilename("fullpath"));
    testsRoot = fileparts(helperTests);
    root = fileparts(testsRoot);
end
