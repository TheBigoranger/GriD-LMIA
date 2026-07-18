function results = run_all
    %RUN_ALL Run the current MATLAB unit tests.
    %
    %   Syntax:
    %     results = tests.run_all()
    %
    %   Example:
    %     results = tests.run_all();
    root = fileparts(mfilename("fullpath"));
    results = [runtests(fullfile(root, "+installation")), ...
        runtests(fullfile(root, "+helper")), ...
        runtests(fullfile(root, "+pdbase")), ...
        runtests(fullfile(root, "+pdmat")), ...
        runtests(fullfile(root, "+pdvar")), ...
        runtests(fullfile(root, "+pdlmi"))];
    assertSuccess(results);
end
