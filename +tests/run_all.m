function results = run_all
    %RUN_ALL Run the current MATLAB unit tests.
    %
    %   Syntax:
    %     results = tests.run_all()
    %
    %   Example:
    %     results = tests.run_all();
    root = fileparts(mfilename("fullpath"));
    results = [runtests(fullfile(root, "+helper")), ...
        runtests(fullfile(root, "+dpbase")), ...
        runtests(fullfile(root, "+dpmat")), ...
        runtests(fullfile(root, "+dpvar")), ...
        runtests(fullfile(root, "+dplmi"))];
    assertSuccess(results);
end
