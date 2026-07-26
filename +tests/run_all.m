function results = run_all
    %RUN_ALL Run the current MATLAB unit tests.
    %
    %   Syntax:
    %     results = tests.run_all()
    %
    %   Example:
    %     results = tests.run_all();
    root = fileparts(mfilename("fullpath"));
    suiteNames = ["installation", "helper", "pdbase", ...
        "pdmat", "pdvar", "pdlmi"];
    results = [];
    for suiteIndex = 1:numel(suiteNames)
        suiteName = suiteNames(suiteIndex);
        fprintf(1, 'Test suite START %d/%d: %s\n', ...
            suiteIndex, numel(suiteNames), char(suiteName));
        drawnow;
        suiteResults = runtests(fullfile(root, "+" + suiteName));
        if isempty(results)
            results = suiteResults;
        else
            results = [results, suiteResults]; %#ok<AGROW>
        end
        passed = nnz([suiteResults.Passed]);
        failed = nnz([suiteResults.Failed]);
        incomplete = nnz([suiteResults.Incomplete]);
        elapsed = sum([suiteResults.Duration]);
        fprintf(1, ['Test suite DONE  %d/%d: %s, passed=%d, failed=%d, ' ...
            'incomplete=%d, duration=%.3fs\n'], ...
            suiteIndex, numel(suiteNames), char(suiteName), ...
            passed, failed, incomplete, elapsed);
        drawnow;
    end
    assertSuccess(results);
end
