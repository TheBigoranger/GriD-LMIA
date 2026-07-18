function report = install_pd_lmi()
%INSTALL_PD_LMI Validate and persist a usable PD-LMI MATLAB installation.
%   INSTALL_PD_LMI() adds the package source folders to the current MATLAB
%   path, verifies the existing YALMIP installation and a working SDP solver,
%   then saves the path. REPORT = INSTALL_PD_LMI() additionally returns the
%   selected solver and the paths added during this call.

    originalPath = path;
    report = emptyReport();
    try
        [yalmipRoot, yalmipFiles] = validateYalmip();
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
        %#ok<NASGU> yalmipFiles records the validated public entry points.
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
    priority = {"mosek", "copt", "sedumi", "sdpt3", "lmilab"};
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
%ADDPACKAGEPATHS Add source folders only, leaving docs and generated files out.
    candidates = strsplit(genpath(packageRoot), pathsep);
    candidates = candidates(~cellfun(@isempty, candidates));
    keep = cellfun(@(folder) ~isExcludedFolder(folder, packageRoot), candidates);
    candidates = candidates(keep);
    addedPaths = {};
    for k = 1:numel(candidates)
        if ~isOnPath(candidates{k})
            addpath(candidates{k});
            addedPaths{end + 1} = candidates{k}; %#ok<AGROW>
        end
    end
end

function tf = isExcludedFolder(folder, packageRoot)
%ISEXCLUDEDFOLDER Keep non-runtime trees out of MATLAB's persistent path.
    relative = erase(string(folder), string(packageRoot));
    parts = split(replace(relative, "\\", "/"), "/");
    excluded = ["doc", "webpage", "sos_validation", ".git", ".agents", ".codex", ...
        "build", "dist", "node_modules", ".astro", "coverage", "tmp"];
    tf = any(ismember(lower(parts), excluded));
end

function tf = isOnPath(folder)
%ISONPATH Compare path entries exactly, avoiding duplicate repeated installs.
    entries = strsplit(path, pathsep);
    tf = any(strcmpi(entries, folder));
end

function verifyPackageClasses(packageRoot)
%VERIFYPACKAGECLASSES Refuse persistence if another package shadows PD-LMI.
    names = {"pdbase", "pdmat", "pdvar", "pdlmi"};
    for k = 1:numel(names)
        expected = fullfile(packageRoot, ['@' names{k}], [names{k} '.m']);
        hits = which(names{k}, "-all");
        if ischar(hits)
            hits = cellstr(hits);
        end
        if isempty(hits) || ~strcmpi(char(hits{1}), expected)
            found = "not found";
            if ~isempty(hits)
                found = string(hits{1});
            end
            error("install_pd_lmi:PathConflict", ...
                "PD-LMI class '%s' is shadowed by %s.", names{k}, found);
        end
    end
end
