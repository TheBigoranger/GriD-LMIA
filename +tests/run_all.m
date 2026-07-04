function results = run_all
%RUN_ALL Run the current non-SDP MATLAB unit tests.
%
%   Syntax:
%     results = tests.run_all()
%
%   Example:
%     results = tests.run_all();
root = fileparts(mfilename("fullpath"));
results = [runtests(fullfile(root, "+helper")), runtests(fullfile(root, "+dpbase"))];
assertSuccess(results);
end
