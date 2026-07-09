function tf = isZero(val, mode, varargin)
    %ISZERO Classify zero evidence used by dpmat and dpvar algebra.
    %
    %   Syntax:
    %     tf = helper.isZero(val, "num")
    %     tf = helper.isZero(val, "add", matrixSize)
    %     tf = helper.isZero(val, "vals")
    %     tf = helper.isZero(obj, "obj")
    %
    %   Example:
    %     tf = helper.isZero(zeros(2), "add", [2 2]);
    %     A = dpmat({[0 1]}, {0, 0}, Degree=1);
    %     tf = helper.isZero(A, "obj");
    %
    %   Modes separate the four zero notions required by algebra: finite real
    %   numeric arrays ("num"), shape-compatible additive identities ("add"),
    %   nested coefficient payloads ("vals"), and coefficient-backed dpmat or
    %   dpvar objects ("obj").

    if ~(ischar(mode) || (isstring(mode) && isscalar(mode)))
        error("helper:InvalidZeroMode", "Zero-classification mode must be text.");
    end
    mode = lower(string(mode));

    switch mode
        case "num"
            chkArgs(mode, varargin, 0);
            tf = isNum(val);
        case "add"
            chkArgs(mode, varargin, 1);
            sz = varargin{1};
            tf = isNum(val) && (isscalar(val) || isequal(size(val), sz));
        case "vals"
            chkArgs(mode, varargin, 0);
            tf = isVals(val);
        case "obj"
            chkArgs(mode, varargin, 0);
            tf = isObj(val);
        otherwise
            error("helper:InvalidZeroMode", ...
                "Unsupported zero-classification mode: %s.", mode);
    end
end

function chkArgs(mode, args, nArg)
    if numel(args) ~= nArg
        error("helper:InvalidZeroCall", ...
            "Zero-classification mode %s requires %d extra input(s).", mode, nArg);
    end
end

function tf = isNum(val)
    tf = isnumeric(val) && isreal(val) && all(isfinite(val(:))) && ...
        ~isempty(val) && all(val(:) == 0);
end

function tf = isVals(vals)
    if iscell(vals)
        tf = true;
        for k = 1:numel(vals)
            if ~isVals(vals{k})
                tf = false;
                return
            end
        end
        return
    end

    if isstruct(vals)
        tf = isscalar(vals) && isfield(vals, "Constant") && isfield(vals, "Rate") && ...
            isVals(vals.Constant) && isVals(vals.Rate);
        return
    end

    if isa(vals, "sdpvar")
        tf = all(full(getbase(vals)) == 0, "all");
        return
    end

    tf = isnumeric(vals) && all(vals(:) == 0);
end

function tf = isObj(obj)
    if isa(obj, "dpmat")
        % Function-only dpmat objects expose placeholder zeros, not coefficient evidence.
        tf = obj.SourceSummary ~= "function" && isVals(obj.LocalValues);
    elseif isa(obj, "dpvar")
        tf = isVals(obj.LocalValues);
    else
        tf = false;
    end
end
