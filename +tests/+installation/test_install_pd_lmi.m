function tests = test_install_pd_lmi
    % Behavioral regressions for installation.install_pd_lmi.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
%SETUPONCE Keep one mock YALMIP path for the whole suite to avoid class caches.
    originalPath = path;
    testCase.addTeardown(@() path(originalPath));
    mockDir = makeMockYalmip();
    testCase.addTeardown(@() removeMock(mockDir));
    addpath(mockDir, "-begin");
    rehash;
    testCase.TestData.MockDir = mockDir;
    setMock("fallback", 0);
end

function test_fallback_and_repeated_installation(testCase)
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

function test_success_stage_report(testCase)
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

function test_failure_stage_and_cause(testCase)
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

function test_failed_probe_restores_path(testCase)
    setMock("no-solver", 0);
    before = path;

    testCase.verifyError(@() install_pd_lmi(), "install_pd_lmi:NoWorkingSDPSolver");
    testCase.verifyEqual(path, before);
end

function test_user_path_fallback(testCase)
    setMock("fallback", [1 0]);
    report = install_pd_lmi();
    state = getMock();

    testCase.verifyTrue(report.Persisted);
    testCase.verifyEqual(numel(state.SaveCalls), 2);
    testCase.verifyEmpty(state.SaveCalls{1});
    testCase.verifyEqual(state.SaveCalls{2}, ...
        {fullfile(state.UserPath, "pathdef.m")});
end

function test_save_exception_fallback(testCase)
    setMock("fallback", [0 0], 1);
    report = install_pd_lmi();
    state = getMock();

    testCase.verifyTrue(report.Persisted);
    testCase.verifyEqual(numel(state.SaveCalls), 2);
    testCase.verifyEmpty(state.SaveCalls{1});
    testCase.verifyEqual(state.SaveCalls{2}, ...
        {fullfile(state.UserPath, "pathdef.m")});
end

function test_persistence_failure_rollback(testCase)
    setMock("fallback", [1 1]);
    before = path;

    testCase.verifyError(@() install_pd_lmi(), "install_pd_lmi:PathSaveFailed");
    testCase.verifyEqual(path, before);
end

function test_second_persistence_exception_restores_path_and_reports_cause(testCase)
    % Failure after a successful solver probe must not leave a partial install.
    setMock("fallback", [1 0], 2);
    before = path;
    output = evalc(['testCase.verifyError(@() install_pd_lmi(), ' ...
        '"install_pd_lmi:PathSaveFailed");']);
    state = getMock();
    testCase.verifyEqual(path, before);
    testCase.verifyEqual(numel(state.SaveCalls), 2);
    testCase.verifySubstring(output, 'Injected savepath failure.');
    testCase.verifySubstring(output, 'step 5/5');
    % A subsequent valid attempt still succeeds after the failed transaction.
    setMock("fallback", 0);
    recovered = install_pd_lmi();
    testCase.verifyTrue(recovered.Persisted);
end

function test_shadowed_class_rollback(testCase)
    setMock("fallback", 0);
    originalFolder = pwd;
    cd(tempdir);
    folderCleanup = onCleanup(@() cd(originalFolder)); %#ok<NASGU>
    conflictDir = tempname;
    mkdir(fullfile(conflictDir, "@pdmat"));
    writelines(["function obj = pdmat(varargin)", "obj = [];", "end"], ...
        fullfile(conflictDir, "@pdmat", "pdmat.m"));
    addpath(conflictDir, "-begin");
    cleanup = onCleanup(@() removeMock(conflictDir)); %#ok<NASGU>
    before = path;

    testCase.verifyError(@() install_pd_lmi(), "install_pd_lmi:PathConflict");
    testCase.verifyEqual(path, before);
end

function test_missing_yalmip(testCase)
    tempHidYal(testCase.TestData.MockDir);
    cleanup = onCleanup(@() restoreMockYalmip(testCase.TestData.MockDir)); %#ok<NASGU>

    testCase.verifyError(@() install_pd_lmi(), "install_pd_lmi:MissingYALMIP");
end

function test_incomplete_yalmip(testCase)
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
        "Registry", struct("tag", {'mosek','copt','sedumi','sdpt3','lmilab'}), ...
        "RegistryThrow", false, "ProbeThrow", {{'mosek'}}, ...
        "Working", {{'sedumi'}}, "ProbeCalls", {{}}, ...
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
    removeMock(incompleteDir);
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
        "global pd_lmi_install_mock", ...
        "if pd_lmi_install_mock.RegistryThrow, error('mock:Registry','registry failed'); end", ...
        "solvers = pd_lmi_install_mock.Registry;", "end"], ...
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
        "solver=varargin{3}.solver;", ...
        "pd_lmi_install_mock.ProbeCalls{end+1}=solver;", ...
        "if any(strcmpi(solver,pd_lmi_install_mock.ProbeThrow)), error('mock:Probe','probe failed'); end", ...
        "if strcmp(pd_lmi_install_mock.Mode,'fallback') && any(strcmpi(solver,pd_lmi_install_mock.Working))", ...
        "    diagnostics = struct('problem', 0);", ...
        "else", "    diagnostics = struct('problem', 1);", "end", "end"], ...
        fullfile(mockDir, "optimize.m"));
end
function test_solver_priority_and_probe_exceptions(testCase)
    global pd_lmi_install_mock
    priority={'mosek','copt','sedumi','sdpt3','lmilab'};
    for first=1:5
        setMock("fallback",0);
        pd_lmi_install_mock.Registry=struct('tag',fliplr(priority));
        pd_lmi_install_mock.Working=priority(first:end);
        pd_lmi_install_mock.ProbeThrow=priority(1:first-1);
        actual=install_pd_lmi();
        testCase.verifyEqual(actual.Solver,priority{first});
        testCase.verifyEqual(pd_lmi_install_mock.ProbeCalls,priority(1:first));
    end
end

function test_malformed_registry_and_enumeration_failure(testCase)
    global pd_lmi_install_mock
    for registry={[],struct('wrong','mosek'),struct('tag','unknown')}
        setMock("fallback",0);
        pd_lmi_install_mock.Registry=registry{1};
        before=path;
        testCase.verifyError(@() install_pd_lmi(),'install_pd_lmi:NoWorkingSDPSolver');
        testCase.verifyEqual(path,before);
        testCase.verifyEmpty(pd_lmi_install_mock.SaveCalls);
    end
    pd_lmi_install_mock.RegistryThrow=true;
    testCase.verifyError(@() install_pd_lmi(),'install_pd_lmi:NoWorkingSDPSolver');
end

function test_first_nonempty_user_path_and_empty_fallback(testCase)
    global pd_lmi_install_mock
    setMock("fallback",[1 0]);
    first=fullfile(tempdir,'first-user'); second=fullfile(tempdir,'second-user');
    pd_lmi_install_mock.UserPath=[pathsep first pathsep second pathsep];
    actual=install_pd_lmi();
    testCase.verifyTrue(actual.Persisted);
    testCase.verifyEqual(string(pd_lmi_install_mock.SaveCalls{2}{1}),string(fullfile(first,'pathdef.m')));
    setMock("fallback",1);
    pd_lmi_install_mock.UserPath='';
    before=path;
    testCase.verifyError(@() install_pd_lmi(),'install_pd_lmi:PathSaveFailed');
    testCase.verifyEqual(path,before);
end


function removeMock(folder)
    % Only delete the exact test-owned folder under the system temporary root.
    folder=char(java.io.File(folder).getCanonicalPath());
    base=char(java.io.File(tempdir).getCanonicalPath());
    assert(startsWith(lower(folder),[lower(base) filesep]),'Mock path must be under tempdir.');
    if any(strcmpi(strsplit(path,pathsep),folder)), rmpath(folder); end
    if isfolder(folder), rmdir(folder,'s'); end
end
