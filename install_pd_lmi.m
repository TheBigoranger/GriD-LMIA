function report = install_pd_lmi()
%INSTALL_PD_LMI Validate and persist a usable PD-LMI MATLAB installation.
%   INSTALL_PD_LMI() adds the repository root to the end of the current
%   MATLAB path, verifies the existing YALMIP installation and a working SDP
%   solver, then saves the path. REPORT = INSTALL_PD_LMI() additionally
%   returns the selected solver and the paths added during this call.

    originalPath = path;
    report = emptyReport();
    try
        [yalmipRoot, ~] = validateYalmip();
        solver = findWorkingSolver();

        packageRoot = fileparts(mfilename("fullpath"));
        addedPaths = addPackagePaths(packageRoot);
        verifyPackageClasses(packageRoot);

        % Persist only after every dependency, solver, and shadowing check has
        % succeeded. A failed savepath is rolled back with the in-memory path.
        try
            status = savepath;
        catch cause
            throwAsCaller(MException("install_pd_lmi:PathSaveFailed", ...
                "Unable to save the MATLAB path: %s", cause.message));
        end
        if ~isequal(status, 0)
            error("install_pd_lmi:PathSaveFailed", ...
                "MATLAB could not persist the PD-LMI path (savepath returned %d).", status);
        end

        report = struct( ...
            "PackageRoot", packageRoot, ...
            "YALMIPRoot", yalmipRoot, ...
            "Solver", solver, ...
            "AddedPaths", {addedPaths}, ...
            "Persisted", true);
    catch cause
        path(originalPath);
        rethrow(cause);
    end
end

function report = emptyReport()
%EMPTYREPORT Keep the output shape stable if an error is inspected in a debugger.
    report = struct("PackageRoot", "", "YALMIPRoot", "", "Solver", "", ...
        "AddedPaths", {{}}, "Persisted", false);
end

function [root, files] = validateYalmip()
%VALIDATEYALMIP Require a complete pre-existing YALMIP path installation.
    names = {"yalmip", "sdpvar", "sdpsettings", "optimize", "getavailablesolvers"};
    files = cell(size(names));
    for k = 1:numel(names)
        file = which(names{k});
        if isempty(file)
            if k == 1
                error("install_pd_lmi:MissingYALMIP", ...
                    "YALMIP is not on the current MATLAB path. Add YALMIP before installing PD-LMI.");
            end
            error("install_pd_lmi:IncompleteYALMIP", ...
                "YALMIP is incomplete: required entry point '%s' is unavailable.", names{k});
        end
        files{k} = file;
    end

    % sdpvar is a class constructor under the YALMIP root in supported
    % YALMIP layouts; this also works for a test double stored in a child folder.
    root = fileparts(fileparts(files{2}));
    if isempty(root) || ~isfolder(root)
        error("install_pd_lmi:IncompleteYALMIP", ...
            "YALMIP has no discoverable installation root.");
    end
end

function solver = findWorkingSolver()
%FINDWORKINGSOLVER Probe supported SDP solvers in the documented fixed order.
    priority = {'mosek', 'copt', 'sedumi', 'sdpt3', 'lmilab'};
    try
        available = getavailablesolvers(0);
    catch cause
        throwAsCaller(MException("install_pd_lmi:NoWorkingSDPSolver", ...
            "YALMIP could not enumerate SDP solvers: %s", cause.message));
    end

    tags = solverTags(available);
    for k = 1:numel(priority)
        candidate = priority{k};
        if ~any(strcmpi(tags, candidate))
            continue
        end
        if probeSolver(candidate)
            solver = candidate;
            return
        end
    end
    error("install_pd_lmi:NoWorkingSDPSolver", ...
        "No working SDP solver was found. Tried MOSEK, COPT, SeDuMi, SDPT3, and LMILAB.");
end

function tags = solverTags(available)
%SOLVERTAGS Normalise YALMIP's solver registry without assuming field order.
    tags = {};
    if isstruct(available) && isfield(available, "tag")
        tags = {available.tag};
    end
end

function ok = probeSolver(solver)
%PROBESOLVER Solve a tiny bounded SDP; registry presence alone is insufficient.
    ok = false;
    try
        X = sdpvar(2, 2, 'symmetric');
        opts = sdpsettings('solver', solver, 'verbose', 0);
        diagnostics = optimize(X >= eye(2), trace(X), opts);
        ok = isstruct(diagnostics) && isfield(diagnostics, "problem") ...
            && isequal(diagnostics.problem, 0);
    catch
        % An unavailable license, missing executable, or failed solve simply
        % falls through to the next supported solver in the fixed priority.
    end
end

function addedPaths = addPackagePaths(packageRoot)
%ADDPACKAGEPATHS Add the package root without scanning non-runtime trees.
    addedPaths = {};
    if ~isOnPath(packageRoot)
        addpath(packageRoot, "-end");
        addedPaths = {packageRoot};
    end
end

function tf = isOnPath(folder)
%ISONPATH Compare path entries exactly, avoiding duplicate repeated installs.
    entries = strsplit(path, pathsep);
    tf = any(strcmpi(entries, folder));
end

function verifyPackageClasses(packageRoot)
%VERIFYPACKAGECLASSES Refuse persistence if another package shadows PD-LMI.
    names = ["pdbase", "pdmat", "pdvar", "pdlmi"];
    for k = 1:numel(names)
        name = names(k);
        expected = fullfile(packageRoot, "@" + name, name + ".m");
        hits = which(name, "-all");
        if ischar(hits)
            hits = cellstr(hits);
        end
        if isempty(hits) || ~strcmpi(string(hits{1}), expected)
            found = "not found";
            if ~isempty(hits)
                found = string(hits{1});
            end
            error("install_pd_lmi:PathConflict", ...
                "PD-LMI class '%s' is shadowed by %s.", name, found);
        end
    end
end
