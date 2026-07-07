function out = reshape(obj, varargin)
    %RESHAPE Reshape each coefficient payload of a coefficient-backed dpmat.
    %
    %   Syntax:
    %     B = reshape(A, m, n)
    %     B = reshape(A, [m n])
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1:4, 5:8}, Degree=1);
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
        error("dpmat:InvalidReshape", ...
            "dpmat reshape expects exactly two matrix dimensions.");
    end

    isEmpty = cellfun(@isempty, raw);
    if nnz(isEmpty) > 1
        error("dpmat:InvalidReshape", ...
            "At most one reshape dimension may be empty.");
    end

    sz = zeros(1, 2);
    for k = 1:2
        if isEmpty(k)
            continue
        end
        sz(k) = helper.chk(raw{k}, "dpmat:InvalidReshape", ...
            "Reshape dimensions must be positive integer scalars.", ...
            "numeric", "real", "scalar", "finite", "integer", "positive");
    end

    if any(isEmpty)
        known = prod(sz(~isEmpty));
        if mod(total, known) ~= 0
            error("dpmat:InvalidReshape", ...
                "Known reshape dimension must divide the number of matrix entries.");
        end
        sz(isEmpty) = total / known;
    elseif prod(sz) ~= total
        error("dpmat:InvalidReshape", ...
            "Reshape dimensions must preserve the number of matrix entries.");
    end
end
