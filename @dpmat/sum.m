function out = sum(obj, varargin)
    %SUM Sum dpmat coefficient payloads along a matrix dimension.
    %
    %   Syntax:
    %     S = sum(A)
    %     S = sum(A, dim)
    %     S = sum(A, "all")
    %
    %   Example:
    %     A = dpmat({[0 1]}, {[1 2; 3 4], 2 * [1 2; 3 4]}, Degree=1);
    %     S = sum(A, 2);

    if isempty(varargin)
        out = unOp(obj, @(a) sum(a));
        return
    end
    if numel(varargin) ~= 1
        error("dpmat:InvalidSum", "dpmat sum accepts at most one dimension argument.");
    end

    dim = varargin{1};
    if (ischar(dim) || (isstring(dim) && isscalar(dim))) && strcmpi(string(dim), "all")
        out = unOp(obj, @(a) sum(a, "all"));
        return
    end

    dim = helper.chk(dim, "dpmat:InvalidSum", ...
        "Sum dimension must be a positive integer scalar or ""all"".", ...
        "numeric", "real", "scalar", "finite", "integer", "positive");
    out = unOp(obj, @(a) sum(a, double(dim)));
end
