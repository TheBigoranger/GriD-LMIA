function api_gate(results, map, api)
    %API_GATE Check maintained traceability against reflection and existing results.
    % Optional map/api inputs support synthetic negative tests without rerunning tests.
    if nargin < 2
        map = jsondecode(fileread(fullfile(fileparts(mfilename('fullpath')), 'api_map.json')));
    end
    if nargin < 3, api = tests.infrastructure.public_api(); end
    keys = string({map.Owner})' + "." + string({map.Method})';
    expected = api(:,1) + "." + api(:,2);
    assert(numel(unique(keys)) == numel(keys), 'tests:DuplicateApi', 'Duplicate API entries.');
    assert(isempty(setxor(keys, expected)), 'tests:ApiMismatch', ...
        'Missing or stale API entries: %s', strjoin(setxor(keys, expected), ', '));
    names = string({results.Name});
    for k = 1:numel(map)
        entry = map(k);
        assert(strlength(string(entry.Contract)) > 0 && ...
            strlength(string(entry.Oracle)) > 0 && strlength(string(entry.Invalid)) > 0, ...
            'tests:MissingContract', 'Contract/oracle/invalid-use explanation is required.');
        mapped = string(entry.Tests);
        assert(~isempty(mapped), 'tests:MissingTest', 'No tests mapped for %s.', keys(k));
        for name = reshape(mapped,1,[])
            owners = string(entry.Owner);
            if owners == "helper"
                % Shared internal mechanics are verified at public calling seams.
                owners = ["helper","pdbase","pdmat","pdvar","pdlmi"];
            end
            assert(any(startsWith(name, "tests." + owners + ".")), ...
                'tests:WrongOwner', 'Wrong calling-class ownership: %s.', name);
            index = find(names == name);
            assert(isscalar(index), 'tests:MissingTest', 'Missing or duplicate test: %s.', name);
            result = results(index);
            assert(result.Passed && ~result.Failed && ~result.Incomplete, ...
                'tests:UnverifiedApi', 'Mapped test failed or is incomplete: %s.', name);
        end
    end
    fprintf('API traceability gate: %d public entries verified.\n', numel(map));
end
