function out = sum(obj, varargin)
    %SUM Sum dpvar coefficient payloads along a matrix dimension.
    %
    %   Syntax:
    %     S = sum(P)
    %     S = sum(P, dim)
    %     S = sum(P, "all")
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "full");
    %     S = sum(P, 2);

    if isempty(varargin)
        out = unOp(obj, @(a) sum(a));
        return
    end
    if numel(varargin) ~= 1
        error("dpvar:InvalidSum", "dpvar sum accepts at most one dimension argument.");
    end

    dim = varargin{1};
    if (ischar(dim) || (isstring(dim) && isscalar(dim))) && strcmpi(string(dim), "all")
        out = unOp(obj, @(a) sum(a, "all"), [1 1]);
        return
    end

    dim = helper.chk(dim, "dpvar:InvalidSum", ...
        "Sum dimension must be a positive integer scalar or ""all"".", ...
        "numeric", "real", "scalar", "finite", "integer", "positive");
    out = unOp(obj, @(a) sum(a, double(dim)));
end
