function [positional, mode] = parseApplyValidation(args)
    %PARSEAPPLYVALIDATION Remove one trailing ValidationMode option.

    positional = args;
    mode = "fast";
    matches = false(1, numel(args));
    for k = 1:numel(args)
        value = args{k};
        matches(k) = (ischar(value) && isrow(value) && ...
            strcmp(value, "ValidationMode")) || ...
            (isstring(value) && isscalar(value) && ~ismissing(value) && ...
            value == "ValidationMode");
    end
    positions = find(matches);
    if isempty(positions)
        return
    end
    if numel(positions) ~= 1 || positions ~= numel(args) - 1
        error("pdlmi:InvalidValidationMode", ...
            "ValidationMode must be supplied once as the trailing Name=Value option.");
    end
    mode = normalizeMode(args{end});
    positional = args(1:end - 2);
end

function mode = normalizeMode(value)
    %NORMALIZEMODE Validate one transient validation-mode value.
    if ~((ischar(value) && isrow(value) && ~isempty(value)) || ...
            (isstring(value) && isscalar(value) && ~ismissing(value)))
        error("pdlmi:InvalidValidationMode", ...
            "ValidationMode must be the scalar text 'fast' or 'strict'.");
    end
    mode = lower(string(value));
    if ~any(mode == ["fast", "strict"])
        error("pdlmi:InvalidValidationMode", ...
            "ValidationMode must be the scalar text 'fast' or 'strict'.");
    end
end
