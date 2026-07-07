function [rows, cols] = matSubs(subs, sz, errId)
    %MATSUBS Normalize dpmat two-dimensional matrix subscripts.

    if numel(subs) ~= 2
        error(errId, "Matrix indexing requires row and column subscripts.");
    end
    rows = oneSub(subs{1}, sz(1), errId);
    cols = oneSub(subs{2}, sz(2), errId);
end

function idx = oneSub(sub, n, errId)
    if (ischar(sub) && strcmp(sub, ":")) || (isstring(sub) && isscalar(sub) && sub == ":")
        idx = 1:n;
        return
    end

    if islogical(sub)
        if ~isvector(sub) || numel(sub) ~= n
            error(errId, "Logical matrix subscripts must match the indexed dimension.");
        end
        idx = find(reshape(sub, 1, []));
        return
    end

    if ~isnumeric(sub) || ~isreal(sub) || ~isvector(sub) || isempty(sub) || ...
            any(~isfinite(sub)) || any(sub ~= fix(sub)) || any(sub < 1) || any(sub > n)
        error(errId, "Matrix subscripts must be valid positive integer indices or ':'.");
    end
    idx = reshape(double(sub), 1, []);
end
