function out = mean(obj, varargin)
    %MEAN Average pdmat coefficient payloads along a matrix dimension.
    %
    %   Syntax:
    %     M = mean(A)
    %     M = mean(A, dim)
    %     M = mean(A, "all")
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2; 3 4], 2 * [1 2; 3 4]}, Degree=1);
    %     M = mean(A, "all");

    if isempty(varargin)
        out = unOp(obj, @(a) mean(a));
        return
    end
    if numel(varargin) ~= 1
        error("pdmat:InvalidMean", "pdmat mean accepts at most one dimension argument.");
    end

    dim = varargin{1};
    if (ischar(dim) || (isstring(dim) && isscalar(dim))) && strcmpi(string(dim), "all")
        out = unOp(obj, @(a) mean(a, "all"));
        return
    end

    dim = helper.chk(dim, "pdmat:InvalidMean", ...
        "Mean dimension must be a positive integer scalar or ""all"".", ...
        "numeric", "real", "scalar", "finite", "integer", "positive");
    out = unOp(obj, @(a) mean(a, double(dim)));
end
