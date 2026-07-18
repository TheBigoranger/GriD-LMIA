function solver = select_sdp_solver()
%SELECT_SDP_SOLVER Select a working YALMIP SDP solver for smoke tests.
%   The test policy deliberately mirrors install_pd_lmi: commercial solvers
%   are preferred when available, then open-source fallbacks are probed.

    priority = {"mosek", "copt", "sedumi", "sdpt3", "lmilab"};
    available = getavailablesolvers(0);
    tags = {};
    if isstruct(available) && isfield(available, "tag")
        tags = {available.tag};
    end

    for k = 1:numel(priority)
        candidate = priority{k};
        if ~any(strcmpi(tags, candidate))
            continue
        end
        try
            X = sdpvar(2, 2, 'symmetric');
            diagnostics = optimize(X >= eye(2), trace(X), ...
                sdpsettings('solver', candidate, 'verbose', 0));
            if diagnostics.problem == 0
                solver = candidate;
                return
            end
        catch
            % Continue to the next documented fallback.
        end
    end

    error("tests:NoWorkingSDPSolver", ...
        "No working SDP solver was found in the MOSEK/COPT/SeDuMi/SDPT3/LMILAB policy.");
end
