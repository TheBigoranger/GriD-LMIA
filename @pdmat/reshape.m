function out = reshape(obj, varargin)
    %RESHAPE Reshape each coefficient payload of a coefficient-backed pdmat.
    %
    %   Syntax:
    %     B = reshape(A, m, n)
    %     B = reshape(A, [m n])
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1:4, 5:8}, Degree=1);
    %     B = reshape(A, 2, 2);

    sz = parseSz(varargin, prod(obj.MatrixSize));
    out = unOp(obj, @(a) reshape(a, sz));
end

function sz = parseSz(args, total)
    if numel(args) == 1 && isnumeric(args{1}) && isvector(args{1})
        raw = num2cell(args{1});
    else
        raw = args;
    end
    if numel(raw) ~= 2
        error("pdmat:InvalidReshape", ...
            "pdmat reshape expects exactly two matrix dimensions.");
    end

    isEmpty = cellfun(@isempty, raw);
    if nnz(isEmpty) > 1
        error("pdmat:InvalidReshape", ...
            "At most one reshape dimension may be empty.");
    end

    sz = zeros(1, 2);
    for k = 1:2
        if isEmpty(k)
            continue
        end
        sz(k) = helper.chk(raw{k}, "pdmat:InvalidReshape", ...
            "Reshape dimensions must be positive integer scalars.", ...
            "numeric", "real", "scalar", "finite", "integer", "positive");
    end

    if any(isEmpty)
        known = prod(sz(~isEmpty));
        if mod(total, known) ~= 0
            error("pdmat:InvalidReshape", ...
                "Known reshape dimension must divide the number of matrix entries.");
        end
        sz(isEmpty) = total / known;
    elseif prod(sz) ~= total
        error("pdmat:InvalidReshape", ...
            "Reshape dimensions must preserve the number of matrix entries.");
    end
end
