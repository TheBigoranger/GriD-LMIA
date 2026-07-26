function out = sum(obj, varargin)
    %SUM Sum coefficient payloads along one or more matrix dimensions.
    %
    %   Syntax:
    %     S = sum(A)
    %     S = sum(A, dim)
    %     S = sum(A, vecdim)
    %     S = sum(A, "all")
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2; 3 4], [2 4; 6 8]}, Degree=1);
    %     S = sum(A, [1 2]);

    if isempty(varargin)
        out = unOp(obj, @(a) sum(a));
        return
    end

    prefix = string(class(obj));
    if numel(varargin) ~= 1
        error(prefix + ":InvalidSum", ...
            "%s sum accepts one dimension vector or ""all"".", prefix);
    end

    arg = varargin{1};
    if ischar(arg) || (isstring(arg) && isscalar(arg))
        if strcmpi(string(arg), "all")
            out = unOp(obj, @(a) sum(a, "all"), [1 1]);
            return
        end
        error(prefix + ":InvalidSum", ...
            "Sum dimension must be a unique positive integer vector or ""all"".");
    end

    dims = parseDims(arg, prefix + ":InvalidSum", "Sum");
    out = unOp(obj, @(a) reduce(a, dims));
end

function dims = parseDims(dims, errId, name)
    %PARSEDIMS Normalize a nonempty unique positive-integer dimension vector.
    dims = helper.chk(dims, errId, ...
        name + " dimensions must be a nonempty unique positive integer vector.", ...
        "numeric", "real", "vector", "nonempty", "finite", "integer", "positive");
    dims = reshape(double(dims), 1, []);
    if numel(unique(dims)) ~= numel(dims)
        error(errId, ...
            "%s dimensions must be a nonempty unique positive integer vector.", name);
    end
end

function val = reduce(val, dims)
    %REDUCE Dimensions above two are singleton no-ops for matrix payloads.
    for dim = dims
        if dim <= 2
            val = sum(val, dim);
        end
    end
end
