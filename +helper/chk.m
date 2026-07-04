function val = chk(val, errId, msg, varargin)
    %CHK Validate common internal argument predicates.

    opts = struct( ...
        "Size", [], ...
        "Numel", [], ...
        "MinNumel", [], ...
        "Min", [], ...
        "Max", []);
    optNames = string(fieldnames(opts));
    tags = strings(1, 0);

    k = 1;
    while k <= numel(varargin)
        key = string(varargin{k});
        if any(key == optNames)
            if k == numel(varargin)
                error("helper:InvalidValidatorCall", ...
                    "Validator option %s requires a value.", key);
            end
            opts.(key) = varargin{k + 1};
            k = k + 2;
        else
            tags(end + 1) = key; %#ok<AGROW>
            k = k + 1;
        end
    end

    for k = 1:numel(tags)
        switch tags(k)
            case "numeric"
                failIf(~isnumeric(val), errId, msg);
            case "real"
                failIf(~isreal(val), errId, msg);
            case "cell"
                failIf(~iscell(val), errId, msg);
            case "struct"
                failIf(~isstruct(val), errId, msg);
            case "nonempty"
                failIf(isempty(val), errId, msg);
            case "scalar"
                failIf(~isscalar(val), errId, msg);
            case "vector"
                failIf(~isvector(val), errId, msg);
            case "finite"
                failIf(~isnumeric(val) || any(~isfinite(val), "all"), errId, msg);
            case "integer"
                failIf(~isnumeric(val) || any(fix(val) ~= val, "all"), errId, msg);
            case "positive"
                failIf(~isnumeric(val) || any(val < 1, "all"), errId, msg);
            case "nonnegative"
                failIf(~isnumeric(val) || any(val < 0, "all"), errId, msg);
            case "increasing"
                failIf(~isnumeric(val) || any(diff(val) <= 0), errId, msg);
            case "rowbounds"
                failIf(~isnumeric(val) || size(val, 2) ~= 2 || any(val(:, 1) > val(:, 2)), ...
                    errId, msg);
            otherwise
                error("helper:InvalidValidatorCall", ...
                    "Unknown validator tag %s.", tags(k));
        end
    end

    if ~isempty(opts.Size)
        failIf(~isequal(size(val), opts.Size), errId, msg);
    end
    if ~isempty(opts.Numel)
        failIf(numel(val) ~= opts.Numel, errId, msg);
    end
    if ~isempty(opts.MinNumel)
        failIf(numel(val) < opts.MinNumel, errId, msg);
    end
    if ~isempty(opts.Min)
        failIf(~isnumeric(val) || any(val < opts.Min, "all"), errId, msg);
    end
    if ~isempty(opts.Max)
        failIf(~isnumeric(val) || any(val > opts.Max, "all"), errId, msg);
    end
end

function failIf(cond, errId, msg)
    if cond
        error(errId, msg);
    end
end
