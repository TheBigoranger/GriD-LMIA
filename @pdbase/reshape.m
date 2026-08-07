function out = reshape(obj, varargin)
    %RESHAPE Reshape every coefficient payload to a two-dimensional size.
    %
    %   Syntax:
    %     B = reshape(A, m, n)
    %     B = reshape(A, [m n])
    %
    %   Output:
    %     B - Same dynamic class with each coefficient reshaped to [m n].
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2; 3 4], [2 4; 6 8]}, Degree=1);
    %     B = reshape(A, 4, 1);

    prefix = string(class(obj));
    sz = parseSz(varargin, prod(obj.MatrixSize), prefix);
    out = mapUnary(obj, @(a) reshape(a, sz), sz);
end

function sz = parseSz(args, total, prefix)
    %PARSESZ Validate the supported two-dimensional reshape forms.
    if numel(args) == 1 && isnumeric(args{1}) && isvector(args{1})
        raw = num2cell(args{1});
    else
        raw = args;
    end
    if numel(raw) ~= 2
        error(prefix + ":InvalidReshape", ...
            "%s reshape expects exactly two matrix dimensions.", prefix);
    end

    isEmpty = cellfun(@isempty, raw);
    if nnz(isEmpty) > 1
        error(prefix + ":InvalidReshape", ...
            "At most one reshape dimension may be empty.");
    end

    sz = zeros(1, 2);
    for k = 1:2
        if isEmpty(k)
            continue
        end
        sz(k) = helper.chk(raw{k}, prefix + ":InvalidReshape", ...
            "reshape dimension", ...
            "numeric", "real", "scalar", "finite", "integer", "positive");
    end

    if any(isEmpty)
        known = prod(sz(~isEmpty));
        if mod(total, known) ~= 0
            error(prefix + ":InvalidReshape", ...
                "Known reshape dimension must divide the number of matrix entries.");
        end
        sz(isEmpty) = total / known;
    elseif prod(sz) ~= total
        error(prefix + ":InvalidReshape", ...
            "Reshape dimensions must preserve the number of matrix entries.");
    end
end
