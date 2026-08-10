function tests = test_install_pd_lmi
%TEST_INSTALL_PD_LMI Isolated dependency, fallback, rollback, and save tests.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
%SETUPONCE Keep one mock YALMIP path for the whole suite to avoid class caches.
    originalPath = path;
    testCase.addTeardown(@() path(originalPath));
    mockDir = makeMockYalmip();
    addpath(mockDir, "-begin");
    rehash;
    testCase.TestData.MockDir = mockDir;
    setMock("fallback", 0);
end

function testFalRepAndRepRun(testCase)
    setMock("fallback", 0);
    first = install_pd_lmi();
    second = install_pd_lmi();
    state = getMock();

    testCase.verifyEqual(first.Solver, 'sedumi');
    testCase.verifyTrue(first.Persisted);
    testCase.verifyEqual(second.Solver, first.Solver);
    testCase.verifyTrue(isfolder(first.PackageRoot));
    testCase.verifyTrue(isfolder(first.YALMIPRoot));
    testCase.verifyTrue(all(strcmpi(first.AddedPaths, first.PackageRoot)));
    testCase.verifyEmpty(second.AddedPaths);
    testCase.verifyEqual(numel(state.SaveCalls), 2);
    testCase.verifyEmpty(state.SaveCalls{1});
    testCase.verifyEmpty(state.SaveCalls{2});
end

function testSucRunPriAllSte(testCase)
%TESTSUCRUNPRIALLSTE Report every installation stage and final success.
    setMock("fallback", 0);

    output = evalc('install_pd_lmi();');

    expected = ["Step 1/5: Validating YALMIP", ...
        "Step 2/5: Finding a working SDP solver", ...
        "Step 3/5: Adding GriD-LMIA to the MATLAB path", ...
        "Step 4/5: Verifying GriD-LMIA class resolution", ...
        "Step 5/5: Persisting the MATLAB path", ...
        "Installation completed successfully"];
    for k = 1:numel(expected)
        testCase.verifySubstring(output, expected(k));
    end
end

function testFaiRunPriSteAndCau(testCase)
%TESTFAIRUNPRISTEANDCAU Print the active stage and original error details.
    setMock("no-solver", 0);
    before = path;

    output = evalc(['testCase.verifyError(@() install_pd_lmi(), ' ...
        '"install_pd_lmi:NoWorkingSDPSolver");']);

    testCase.verifySubstring(output, ...
        "Installation failed during step 2/5: Finding a working SDP solver");
    testCase.verifySubstring(output, "install_pd_lmi:NoWorkingSDPSolver");
    testCase.verifySubstring(output, "No working SDP solver was found");
    testCase.verifyEqual(path, before);
end

function testFaiProRolBacPat(testCase)
    setMock("no-solver", 0);
    before = path;

    testCase.verifyError(@() install_pd_lmi(), "install_pd_lmi:NoWorkingSDPSolver");
    testCase.verifyEqual(path, before);
end

function testNonPriSavUseUse(testCase)
    setMock("fallback", [1 0]);
    report = install_pd_lmi();
    state = getMock();

    testCase.verifyTrue(report.Persisted);
    testCase.verifyEqual(numel(state.SaveCalls), 2);
    testCase.verifyEmpty(state.SaveCalls{1});
    testCase.verifyEqual(state.SaveCalls{2}, ...
        {fullfile(state.UserPath, "pathdef.m")});
end

function testPriSavExcUseUse(testCase)
    setMock("fallback", [0 0], 1);
    report = install_pd_lmi();
    state = getMock();

    testCase.verifyTrue(report.Persisted);
    testCase.verifyEqual(numel(state.SaveCalls), 2);
    testCase.verifyEmpty(state.SaveCalls{1});
    testCase.verifyEqual(state.SaveCalls{2}, ...
        {fullfile(state.UserPath, "pathdef.m")});
end

function testPerFaiRolBacPat(testCase)
    setMock("fallback", [1 1]);
    before = path;

    testCase.verifyError(@() install_pd_lmi(), "install_pd_lmi:PathSaveFailed");
    testCase.verifyEqual(path, before);
end

function testShaClaRolBacPat(testCase)
    setMock("fallback", 0);
    originalFolder = pwd;
    cd(tempdir);
    folderCleanup = onCleanup(@() cd(originalFolder)); %#ok<NASGU>
    conflictDir = tempname;
    mkdir(fullfile(conflictDir, "@pdmat"));
    writelines(["function obj = pdmat(varargin)", "obj = [];", "end"], ...
        fullfile(conflictDir, "@pdmat", "pdmat.m"));
    addpath(conflictDir, "-begin");
    cleanup = onCleanup(@() rmpath(conflictDir)); %#ok<NASGU>
    before = path;

    testCase.verifyError(@() install_pd_lmi(), "install_pd_lmi:PathConflict");
    testCase.verifyEqual(path, before);
end

function testMissingYalmip(testCase)
    tempHidYal(testCase.TestData.MockDir);
    cleanup = onCleanup(@() restoreMockYalmip(testCase.TestData.MockDir)); %#ok<NASGU>

    testCase.verifyError(@() install_pd_lmi(), "install_pd_lmi:MissingYALMIP");
end

function testIncompleteYalmip(testCase)
    tempHidYal(testCase.TestData.MockDir);
    incompleteDir = tempname;
    mkdir(incompleteDir);
    writelines(["function varargout = yalmip(varargin)", "varargout = cell(1,nargout);", "end"], ...
        fullfile(incompleteDir, "yalmip.m"));
    addpath(incompleteDir, "-begin");
    cleanup = onCleanup(@() restIncMoc(incompleteDir, testCase.TestData.MockDir)); %#ok<NASGU>

    testCase.verifyError(@() install_pd_lmi(), "install_pd_lmi:IncompleteYALMIP");
end

function setMock(mode, saveStatus, throwCalls)
%SETMOCK Control the shared solver and savepath doubles deterministically.
    if nargin < 3
        throwCalls = [];
    end
    global pd_lmi_install_mock
    pd_lmi_install_mock = struct( ...
        "Mode", mode, ...
        "SaveStatus", saveStatus, ...
        "ThrowCalls", throwCalls, ...
        "SaveCalls", {{}}, ...
        "UserPath", fullfile(tempdir, "pd_lmi_install_user"));
end

function state = getMock()
%GETMOCK Return the current savepath call log for assertions.
    global pd_lmi_install_mock
    state = pd_lmi_install_mock;
end

function tempHidYal(mockDir)
%TEMPORARILYHIDEYALMIP Remove both the mock and the real YALMIP path.
    rmpath(mockDir);
    entry = which('sdpvar');
    root = fileparts(fileparts(entry));
    if ~isempty(entry) && isfolder(root)
        entries = strsplit(path, pathsep);
        prefix = [root filesep];
        underRoot = strcmpi(entries, root) | ...
            startsWith(entries, prefix, "IgnoreCase", true);
        for k = find(underRoot)
            rmpath(entries{k});
        end
    end
    rehash;
end

function restoreMockYalmip(mockDir)
%RESTOREMOCKYALMIP Restore the shared mock path after dependency tests.
    addpath(mockDir, "-begin");
    setMock("fallback", 0);
    rehash;
end

function restIncMoc(incompleteDir, mockDir)
%RESTOREINCOMPLETEMOCK Restore both path priority and the shared mock state.
    rmpath(incompleteDir);
    restoreMockYalmip(mockDir);
end

function mockDir = makeMockYalmip()
%MAKEMOCKYALMIP Build minimal YALMIP doubles for deterministic installer tests.
    mockDir = tempname;
    mkdir(mockDir);
    writelines(["function varargout = yalmip(varargin)", "varargout = cell(1,nargout);", "end"], ...
        fullfile(mockDir, "yalmip.m"));
    writelines(["function X = sdpvar(varargin)", "X = eye(2);", "end"], ...
        fullfile(mockDir, "sdpvar.m"));
    writelines(["function opts = sdpsettings(varargin)", ...
        "opts = struct('solver', varargin{2});", "end"], ...
        fullfile(mockDir, "sdpsettings.m"));
    writelines(["function solvers = getavailablesolvers(varargin)", ...
        "solvers = struct('tag', {'mosek', 'copt', 'sedumi'});", "end"], ...
        fullfile(mockDir, "getavailablesolvers.m"));
    writelines(["function status = savepath(varargin)", ...
        "global pd_lmi_install_mock", ...
        "pd_lmi_install_mock.SaveCalls{end + 1} = varargin;", ...
        "callIndex = numel(pd_lmi_install_mock.SaveCalls);", ...
        "if any(callIndex == pd_lmi_install_mock.ThrowCalls)", ...
        "    error('mock:SavePathFailure', 'Injected savepath failure.');", ...
        "end", ...
        "statusIndex = min(callIndex, numel(pd_lmi_install_mock.SaveStatus));", ...
        "status = pd_lmi_install_mock.SaveStatus(statusIndex);", ...
        "end"], ...
        fullfile(mockDir, "savepath.m"));
    writelines(["function folder = userpath", ...
        "global pd_lmi_install_mock", ...
        "folder = pd_lmi_install_mock.UserPath;", ...
        "end"], ...
        fullfile(mockDir, "userpath.m"));
    writelines(["function diagnostics = optimize(varargin)", ...
        "global pd_lmi_install_mock", ...
        "if strcmp(pd_lmi_install_mock.Mode, 'fallback') && strcmpi(varargin{3}.solver, 'sedumi')", ...
        "    diagnostics = struct('problem', 0);", ...
        "else", "    diagnostics = struct('problem', 1);", "end", "end"], ...
        fullfile(mockDir, "optimize.m"));
end
