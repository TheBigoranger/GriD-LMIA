function tf = isequal(varargin)
    %ISEQUAL True when dpmat objects have identical metadata and coefficients.
    %
    %   Syntax:
    %     tf = isequal(A, B)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     tf = isequal(A, A);

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
    tf = builtin("isequal", a.MatrixSize, b.MatrixSize) && ...
        builtin("isequal", a.Degree, b.Degree) && ...
        builtin("isequal", a.GridInfo.Vectors, b.GridInfo.Vectors) && ...
        builtin("isequal", a.LocalValues, b.LocalValues) && ...
        builtin("isequal", a.IsContinuous, b.IsContinuous) && ...
        builtin("isequal", a.ContainsDecision, b.ContainsDecision) && ...
        builtin("isequal", a.HasRateDependence, b.HasRateDependence) && ...
        builtin("isequal", a.RateBounds, b.RateBounds) && ...
        builtin("isequal", a.SourceSummary, b.SourceSummary) && ...
        builtin("isequal", a.FunctionHandle, b.FunctionHandle);
end
