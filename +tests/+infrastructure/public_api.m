function api = public_api
    %PUBLIC_API Discover package-defined public methods and production helpers.
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    folders = dir(fullfile(root, '@*'));
    folders = folders([folders.isdir]);
    classes = extractAfter(string({folders.name}), '@');
    api = strings(0, 2);
    for owner = classes
        info = meta.class.fromName(owner);
        for method = reshape(info.MethodList, 1, [])
            defining = string(method.DefiningClass.Name);
            if ~ischar(method.Access) || ~strcmp(method.Access, 'public') ...
                    || ~any(defining == classes)
                continue
            end
            name = string(method.Name);
            if any(name == classes) && name ~= owner, continue; end
            % MATLAB synthesizes empty for value classes; it is not package code.
            if name == "empty" && ~isfile(fullfile(root, '@'+defining, 'empty.m'))
                source = fileread(fullfile(root, '@'+defining, defining+'.m'));
                if isempty(regexp(source, 'function[^\n]*\bempty\s*\(', 'once'))
                    continue
                end
            end
            api(end+1,:) = [owner name]; %#ok<AGROW>
        end
    end
    files = dir(fullfile(root, '+helper', '*.m'));
    for k = 1:numel(files)
        [~, name] = fileparts(files(k).name);
        api(end+1,:) = ["helper", string(name)]; %#ok<AGROW>
    end
    api(end+1,:) = ["installation", "install_pd_lmi"];
    api = sortrows(unique(api, 'rows'));
end
