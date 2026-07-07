function out = mean(obj, varargin)
    %MEAN Average dpvar coefficient payloads along a matrix dimension.
    %
    %   Syntax:
    %     M = mean(P)
    %     M = mean(P, dim)
    %     M = mean(P, "all")
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "full");
    %     M = mean(P, "all");

    if isempty(varargin)
        out = unOp(obj, @(a) mean(a));
        return
    end
    if numel(varargin) ~= 1
        error("dpvar:InvalidMean", "dpvar mean accepts at most one dimension argument.");
    end

    dim = varargin{1};
    if (ischar(dim) || (isstring(dim) && isscalar(dim))) && strcmpi(string(dim), "all")
        out = unOp(obj, @(a) mean(a, "all"), [1 1]);
        return
    end

    dim = helper.chk(dim, "dpvar:InvalidMean", ...
        "Mean dimension must be a positive integer scalar or ""all"".", ...
        "numeric", "real", "scalar", "finite", "integer", "positive");
    out = unOp(obj, @(a) mean(a, double(dim)));
end
