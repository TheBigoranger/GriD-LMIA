function mode = normMode(value, owner)
    %NORMMODE Validate a transient fast/strict validation mode.
    %
    %   Syntax:
    %     mode = helper.normMode(value, owner)
    %
    %   Arguments:
    %     value - Text value supplied through a ValidationMode option.
    %     owner - Package or class stem used in the error identifier.
    %
    %   Output:
    %     mode - Lowercase string scalar, either "fast" or "strict".
    %
    %   Example:
    %     mode = helper.normMode("Strict", "pdlmi");
    %
    %   ValidationMode is intentionally transient. It changes internal
    %   consistency checks during generated assembly, but it is not stored on
    %   package objects or exposed as mathematical state.
    if ~((ischar(value) && isrow(value) && ~isempty(value)) || ...
            (isstring(value) && isscalar(value) && ~ismissing(value)))
        error(owner + ":InvalidValidationMode", ...
            "ValidationMode must be the scalar text 'fast' or 'strict'.");
    end
    mode = lower(string(value));
    if ~any(mode == ["fast", "strict"])
        error(owner + ":InvalidValidationMode", ...
            "ValidationMode must be the scalar text 'fast' or 'strict'.");
    end
end
