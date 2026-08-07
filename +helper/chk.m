function val = chk(val, errId, label, varargin)
    %CHK Validate common internal argument predicates.
    %
    %   Syntax:
    %     val = helper.chk(val, errId, label, tags...)
    %     val = helper.chk(val, errId, label, tags..., Name, Value)
    %
    %   Arguments:
    %     val   - Value to return after validation.
    %     errId - Caller-owned error identifier.
    %     label - Caller-owned value label used in standard messages.
    %     tags  - Named predicates plus optional Size/Numel/range pairs.
    %
    %   Output:
    %     val - The unchanged validated value.
    %
    %   Example:
    %     v = helper.chk([1 2], "pkg:BadValue", "value", ...
    %         "numeric", "real", "finite", "Size", [1 2]);

    if ~isempty(varargin) && strcmp(varargin{1}, "cell")
        if ~iscell(val), failIf(true, errId, label, " must be a cell array."); end
        if numel(varargin) == 1, return; end
        if numel(varargin) == 2 && strcmp(varargin{2}, "nonempty")
            if isempty(val), failIf(true, errId, label, " must be nonempty."); end; return
        elseif numel(varargin) == 3 && strcmp(varargin{2}, "Numel")
            if numel(val) ~= varargin{3}, failIf(true, errId, sprintf( ...
                    "%s must contain %d elements.", label, varargin{3})); end; return
        end
    end
    if numel(varargin) == 2 && strcmp(varargin{1}, "Size")
        if ~isequal(size(val), varargin{2}), failIf(true, errId, sprintf( ...
                "%s must have size %s.", label, mat2str(varargin{2}))); end
        return
    end
    [szOpt, numOpt, minNum, minVal, maxVal] = deal([]);
    badMsg = ""; badKey = "";
    k = 1;
    while k <= numel(varargin)
        key = string(varargin{k});
        switch key
            case "numeric", if badMsg == "" && badKey == "" && ~isnumeric(val), badMsg = " must be numeric."; end
            case "real", if badMsg == "" && badKey == "" && ~isreal(val), badMsg = " must be real."; end
            case "cell", if badMsg == "" && badKey == "" && ~iscell(val), badMsg = " must be a cell array."; end
            case "struct", if badMsg == "" && badKey == "" && ~isstruct(val), badMsg = " must be a structure."; end
            case "nonempty", if badMsg == "" && badKey == "" && isempty(val), badMsg = " must be nonempty."; end
            case "scalar", if badMsg == "" && badKey == "" && ~isscalar(val), badMsg = " must be scalar."; end
            case "vector", if badMsg == "" && badKey == "" && ~isvector(val), badMsg = " must be a vector."; end
            case "matrix", if badMsg == "" && badKey == "" && ~ismatrix(val), badMsg = " must be a matrix."; end
            case "finite"
                if badMsg == "" && badKey == "" && (~isnumeric(val) || any(~isfinite(val), "all"))
                    badMsg = " must be finite.";
                end
            case "integer"
                if badMsg == "" && badKey == "" && (~isnumeric(val) || any(fix(val) ~= val, "all"))
                    badMsg = " must contain integers.";
                end
            case "positive"
                if badMsg == "" && badKey == "" && (~isnumeric(val) || any(val < 1, "all"))
                    badMsg = " must be positive.";
                end
            case "nonnegative"
                if badMsg == "" && badKey == "" && (~isnumeric(val) || any(val < 0, "all"))
                    badMsg = " must be nonnegative.";
                end
            case "increasing"
                if badMsg == "" && badKey == "" && (~isnumeric(val) || any(diff(val) <= 0))
                    badMsg = " must be strictly increasing.";
                end
            case "rowbounds"
                bad = ~isnumeric(val) || size(val, 2) ~= 2 || any(val(:, 1) > val(:, 2));
                if badMsg == "" && badKey == "" && bad, badMsg = " must contain lower-upper row bounds."; end
            case {"Size", "Numel", "MinNumel", "Min", "Max"}
                if k == numel(varargin)
                    error("helper:InvalidValidatorCall", ...
                        "Validator option %s requires a value.", key);
                end
                switch key
                    case "Size", szOpt = varargin{k + 1};
                    case "Numel", numOpt = varargin{k + 1};
                    case "MinNumel", minNum = varargin{k + 1};
                    case "Min", minVal = varargin{k + 1};
                    case "Max", maxVal = varargin{k + 1};
                end
                k = k + 1;
            otherwise
                if badMsg == "" && badKey == "", badKey = key; end
        end
        k = k + 1;
    end
    if badMsg ~= "", failIf(true, errId, label, badMsg); end
    if badKey ~= ""
        error("helper:InvalidValidatorCall", ...
            "Unknown validator tag %s.", badKey);
    end
    if ~isempty(szOpt) && ~isequal(size(val), szOpt)
        failIf(true, errId, sprintf("%s must have size %s.", label, mat2str(szOpt)));
    end
    if ~isempty(numOpt) && numel(val) ~= numOpt
        failIf(true, errId, sprintf("%s must contain %d elements.", label, numOpt));
    end
    if ~isempty(minNum) && numel(val) < minNum
        failIf(true, errId, sprintf("%s must contain at least %d elements.", label, minNum));
    end
    if ~isempty(minVal) && (~isnumeric(val) || any(val < minVal, "all"))
        failIf(true, errId, sprintf("%s must be at least %g.", label, minVal));
    end
    if ~isempty(maxVal) && (~isnumeric(val) || any(val > maxVal, "all"))
        failIf(true, errId, sprintf("%s must be at most %g.", label, maxVal));
    end
end
function failIf(cond, errId, msg, suffix)
    if cond
        if nargin > 3
            msg = msg + suffix;
        end
        error(errId, msg);
    end
end
