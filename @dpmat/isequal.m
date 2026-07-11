function tf = isequal(varargin)
    %ISEQUAL True when dpmat objects have equivalent coefficient evidence.
    %
    %   Syntax:
    %     tf = isequal(A, B)
    %
    %   Example:
    %     A = dpmat({[0 1]}, @(rho) rho, Degree=1);
    %     B = dpmat({[0 1]}, {0, 1}, Degree=1);
    %     tf = isequal(A, B);

    if nargin < 2
        tf = true;
        return
    end

    ref = varargin{1};
    if ~isa(ref, "dpmat")
        tf = builtin("isequal", varargin{:});
        return
    end

    tf = true;
    for k = 2:nargin
        val = varargin{k};
        if ~isa(val, "dpmat") || ~sameOne(ref, val)
            tf = false;
            return
        end
    end
end

function tf = sameOne(a, b)
    if ~(builtin("isequal", a.MatrixSize, b.MatrixSize) && ...
            builtin("isequal", a.IsContinuous, b.IsContinuous) && ...
            builtin("isequal", a.ContainsDecision, b.ContainsDecision) && ...
            builtin("isequal", a.HasRateDependence, b.HasRateDependence) && ...
            builtin("isequal", a.RateBounds, b.RateBounds))
        tf = false;
        return
    end

    % Function-only objects have placeholder LocalValues, so compare their
    % metadata and function handles instead of treating placeholders as evidence.
    if a.SourceSummary ~= "function" && b.SourceSummary ~= "function"
        tf = sameEvidence(a, b);
        return
    end

    tf = builtin("isequal", a.Degree, b.Degree) && ...
        builtin("isequal", a.GridInfo.Vectors, b.GridInfo.Vectors) && ...
        builtin("isequal", a.SourceSummary, b.SourceSummary) && ...
        builtin("isequal", a.FunctionHandle, b.FunctionHandle);
end

function tf = sameEvidence(a, b)
    try
        grid = a.mergeGrid("dpmat:InvalidEquality", a, b);
        ad = asData(grid, a, a.MatrixSize, "dpmat:InvalidEquality");
        bd = asData(grid, b, a.MatrixSize, "dpmat:InvalidEquality");
    catch
        tf = false;
        return
    end

    deg = max(ad.Degree, bd.Degree);
    av = elevLocalValues(a, ad.LocalValues, ad.Degree, deg, grid);
    bv = elevLocalValues(a, bd.LocalValues, bd.Degree, deg, grid);
    tf = valsEqual(av, bv);
end

function tf = valsEqual(a, b)
    if iscell(a) || iscell(b)
        if ~(iscell(a) && iscell(b)) || ~isequal(size(a), size(b))
            tf = false;
            return
        end
        tf = true;
        for k = 1:numel(a)
            if ~valsEqual(a{k}, b{k})
                tf = false;
                return
            end
        end
        return
    end

    if ~isequal(size(a), size(b)) || ~isnumeric(a) || ~isnumeric(b)
        tf = false;
        return
    end
    scale = max([1; abs(a(:)); abs(b(:))]);
    tf = all(abs(a(:) - b(:)) <= 1e-9 * scale);
end
