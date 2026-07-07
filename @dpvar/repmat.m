function out = repmat(obj, varargin)
    %REPMAT Repeat each coefficient payload in a two-dimensional block pattern.
    %
    %   Syntax:
    %     Q = repmat(P, m, n)
    %     Q = repmat(P, [m n])
    %
    %   Example:
    %     P = dpvar(1, 2, {[0 1]}, "full");
    %     Q = repmat(P, 2, 1);

    sz = parseRep(varargin);
    out = unOp(obj, @(a) repmat(a, sz), obj.MatrixSize .* sz);
end

function sz = parseRep(args)
    if numel(args) == 1 && isnumeric(args{1}) && isvector(args{1})
        sz = reshape(args{1}, 1, []);
        if isscalar(sz)
            sz = [sz sz];
        end
    elseif numel(args) == 2
        sz = zeros(1, 2);
        for k = 1:2
            sz(k) = helper.chk(args{k}, "dpvar:InvalidRepmat", ...
                "Repetition counts must be positive integer scalars.", ...
                "numeric", "real", "scalar", "finite", "integer", "positive");
        end
        return
    else
        error("dpvar:InvalidRepmat", ...
            "dpvar repmat expects a scalar, a two-element size vector, or two size scalars.");
    end

    if numel(sz) ~= 2
        error("dpvar:InvalidRepmat", ...
            "dpvar repmat supports exactly two matrix repetition counts.");
    end
    for k = 1:2
        sz(k) = helper.chk(sz(k), "dpvar:InvalidRepmat", ...
            "Repetition counts must be positive integer scalars.", ...
            "numeric", "real", "scalar", "finite", "integer", "positive");
    end
end
