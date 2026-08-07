function out = mean(obj, varargin)
    %MEAN Average coefficient payloads along one or more matrix dimensions.
    %
    %   Syntax:
    %     M = mean(A)
    %     M = mean(A, dim)
    %     M = mean(A, vecdim)
    %     M = mean(A, "all")
    %
    %   Output:
    %     M - Same dynamic class with each coefficient replaced by the
    %         requested matrix average.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2; 3 4], [2 4; 6 8]}, Degree=1);
    %     M = mean(A, [1 2]);

    if isempty(varargin)
        out = mapUnary(obj, @(a) mean(a));
        return
    end

    prefix = string(class(obj));
    if numel(varargin) ~= 1
        error(prefix + ":InvalidMean", ...
            "%s mean accepts one dimension vector or ""all"".", prefix);
    end

    arg = varargin{1};
    if ischar(arg) || (isstring(arg) && isscalar(arg))
        if strcmpi(string(arg), "all")
            out = mapUnary(obj, @(a) mean(a, "all"), [1 1]);
            return
        end
        error(prefix + ":InvalidMean", ...
            "Mean dimension must be a unique positive integer vector or ""all"".");
    end

    dims = pdbase.normRedDims(arg, prefix + ":InvalidMean", "Mean");
    out = mapUnary(obj, @(a) reduce(a, dims));
end

function val = reduce(val, dims)
    %REDUCE Dimensions above two are singleton no-ops for matrix payloads.
    for dim = dims
        if dim <= 2
            val = mean(val, dim);
        end
    end
end
