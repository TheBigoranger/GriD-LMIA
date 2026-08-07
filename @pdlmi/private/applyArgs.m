function [positional, mode] = applyArgs(args)
    %APPLYARGS Remove one trailing ValidationMode option from apply inputs.
    %
    %   Syntax:
    %     [positional, mode] = applyArgs(args)
    %
    %   Arguments:
    %     args - Cell array of positional apply-method inputs plus an optional
    %            trailing "ValidationMode", mode pair.
    %
    %   Output:
    %     positional - Inputs before the optional trailing ValidationMode pair.
    %     mode       - "fast" by default, or the normalized requested mode.
    %
    %   Example:
    %     [args, mode] = applyArgs({2, "ValidationMode", "strict"});
    %
    %   Apply methods keep their positional signatures compact. ValidationMode
    %   is accepted only as the final Name/Value pair so certificate-order
    %   arguments cannot be confused with option names.

    positional = args;
    mode = "fast";
    matches = false(1, numel(args));
    for k = 1:numel(args)
        val = args{k};
        matches(k) = (ischar(val) && isrow(val) && ...
            strcmp(val, "ValidationMode")) || ...
            (isstring(val) && isscalar(val) && ~ismissing(val) && ...
            val == "ValidationMode");
    end
    positions = find(matches);
    if isempty(positions)
        return
    end
    if numel(positions) ~= 1 || positions ~= numel(args) - 1
        error("pdlmi:InvalidValidationMode", ...
            "ValidationMode must be supplied once as the trailing Name=Value option.");
    end
    mode = helper.normMode(args{end}, "pdlmi");
    positional = args(1:end - 2);
end
