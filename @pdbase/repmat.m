function out = repmat(obj, varargin)
    %REPMAT Repeat every coefficient payload in a two-dimensional pattern.
    %
    %   Syntax:
    %     B = repmat(A, m, n)
    %     B = repmat(A, [m n])
    %
    %   Output:
    %     B - Same dynamic class with each coefficient repeated in the
    %         requested two-dimensional pattern.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     B = repmat(A, 2, 3);

    prefix = string(class(obj));
    reps = parseRep(varargin, prefix);
    out = mapUnary(obj, @(a) repmat(a, reps), obj.MatrixSize .* reps);
end

function reps = parseRep(args, prefix)
    %PARSEREP Validate scalar and two-dimensional repetition forms.
    if numel(args) == 1 && isnumeric(args{1}) && isvector(args{1})
        reps = reshape(args{1}, 1, []);
        if isscalar(reps)
            reps = [reps reps];
        end
    elseif numel(args) == 2
        reps = zeros(1, 2);
        for k = 1:2
            reps(k) = helper.chk(args{k}, prefix + ":InvalidRepmat", ...
                "repetition count", ...
                "numeric", "real", "scalar", "finite", "integer", "positive");
        end
        return
    else
        error(prefix + ":InvalidRepmat", ...
            "%s repmat expects a scalar, a two-element size vector, or two size scalars.", ...
            prefix);
    end

    if numel(reps) ~= 2
        error(prefix + ":InvalidRepmat", ...
            "%s repmat supports exactly two matrix repetition counts.", prefix);
    end
    for k = 1:2
        reps(k) = helper.chk(reps(k), prefix + ":InvalidRepmat", ...
            "repetition count", ...
            "numeric", "real", "scalar", "finite", "integer", "positive");
    end
end
