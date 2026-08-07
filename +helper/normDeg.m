function degree = normDeg(value, nPar, errId, label)
    %NORMDEG Validate scalar or per-parameter Bernstein degrees.
    %
    %   Syntax:
    %     degree = helper.normDeg(value, nPar, errId)
    %     degree = helper.normDeg(value, nPar, errId, label)
    %
    %   Arguments:
    %     value - Numeric scalar shorthand or ell-element degree vector.
    %     nPar  - Number of parameters in the owning grid.
    %     errId - Error identifier to raise for invalid input.
    %     label - Optional value name used in the diagnostic message.
    %
    %   Output:
    %     degree - 1-by-nPar nonnegative integer row vector.
    %
    %   Example:
    %     deg = helper.normDeg(2, 3, "pdmat:InvalidDegree", "Degree");
    %
    %   The caller owns ERRID and LABEL; scalar input expands to 1-by-NPAR.

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
