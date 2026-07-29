function degree = normalizeDegree(value, nPar, errId, label)
    %NORMALIZEDEGREE Validate scalar or per-parameter Bernstein degrees.
    %
    %   DEGREE = helper.normalizeDegree(VALUE, NPAR, ERRID, LABEL) accepts
    %   one finite nonnegative integer scalar or an NPAR-element vector.
    %   Scalars expand uniformly and every accepted value returns as a
    %   1-by-NPAR double row vector. ERRID remains owned by the caller.

    if nargin < 4 || isempty(label)
        label = "Degree";
    end
    valid = isnumeric(value) && isreal(value) && isvector(value) && ...
        ~isempty(value) && all(isfinite(value(:))) && ...
        all(value(:) == fix(value(:))) && all(value(:) >= 0) && ...
        any(numel(value) == [1, nPar]);
    if ~valid
        error(errId, ...
            "%s must be a finite nonnegative integer scalar or an ell-element vector.", ...
            label);
    end

    degree = reshape(double(value), 1, []);
    if isscalar(degree)
        degree = repmat(degree, 1, nPar);
    end
end
