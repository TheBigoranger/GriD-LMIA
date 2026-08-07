function dims = normRedDims(dims, errId, name)
    %NORMREDDIMS Validate and normalize matrix-reduction dimensions.
    %
    %   Syntax:
    %     dims = pdbase.normRedDims(dims, errId, name)
    %
    %   Arguments:
    %     dims  - Positive integer scalar or vector supplied to a reduction.
    %     errId - Error identifier owned by the public reduction method.
    %     name  - Text label used in diagnostics, such as "sum" or "mean".
    %
    %   Output:
    %     dims - Unique positive integer row vector in double precision.
    %
    %   Example:
    %     dims = pdbase.normRedDims( ...
    %         [2 1], "pdbase:InvalidDimension", "sum");
    %
    %   MATLAB reductions reject repeated dimensions. Keeping that check in
    %   this shared helper keeps sum, mean, and cumulative reductions aligned
    %   without duplicating the same diagnostic wording.
    dims = helper.chk(dims, errId, name + " dimensions", ...
        "numeric", "real", "vector", "nonempty", "finite", ...
        "integer", "positive");
    dims = reshape(double(dims), 1, []);
    if numel(unique(dims)) ~= numel(dims)
        error(errId, ...
            "%s dimensions must be a nonempty unique positive integer vector.", name);
    end
end
