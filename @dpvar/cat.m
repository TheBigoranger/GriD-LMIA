function out = cat(dim, varargin)
    %CAT Concatenate dpvar-compatible coefficient blocks along rows or columns.
    %
    %   Syntax:
    %     C = cat(1, P, Q)
    %     C = cat(2, P, A)
    %
    %   Example:
    %     P = dpvar(2, 1, {[0 1]});
    %     C = cat(2, P, ones(2, 1));

    if ~isnumeric(dim) || ~isscalar(dim) || dim ~= fix(dim) || dim < 1
        error("dpvar:InvalidConcatenation", ...
            "Concatenation dimension must be a positive integer scalar.");
    end
    if dim > 2
        error("dpvar:UnsupportedCatDimension", ...
            "dpvar only supports cat along dimensions 1 and 2.");
    end

    anchor = pickAnchor(varargin);
    grid = anchor.mergeGrid("dpvar:MixedGrid", varargin{:});
    [data, sz] = catData(anchor, dim, varargin, grid);
    deg = max(arrayfun(@(d) d.Degree, data));

    for k = 1:numel(data)
        data(k).LocalValues = elevVals(anchor, data(k).LocalValues, ...
            data(k).Degree, deg, grid);
    end

    nCell = cellfun(@numel, grid) - 1;
    vals = internal.mkNest(nCell, @(subs) catCell(dim, data, subs));
    hasDec = any(arrayfun(@(d) d.ContainsDecision, data));
    hasRate = any(arrayfun(@(d) d.HasRateDependence, data));
    rb = anchor.RateBounds;
    if ~hasRate
        rb = [];
    end

    out = dpvar(mkInit(grid, sz, deg, vals, hasDec, hasRate, rb, "expression"));
    if ~isequal(size(out), sz)
        error("dpvar:InvalidConcatenation", ...
            "Internal dpvar concatenation size mismatch.");
    end
end

function anchor = pickAnchor(args)
    anchor = [];
    for k = 1:numel(args)
        if isa(args{k}, "dpvar")
            anchor = args{k};
            break
        end
    end
    if isempty(anchor)
        error("dpvar:InvalidConcatenation", ...
            "At least one concatenated value must be a dpvar.");
    end
end

function [data, outSize] = catData(anchor, dim, args, grid)
    data = repmat(struct( ...
        "MatrixSize", [], ...
        "Degree", [], ...
        "LocalValues", [], ...
        "ContainsDecision", [], ...
        "HasRateDependence", []), 1, numel(args));
    sz = zeros(numel(args), 2);
    isScalar = false(1, numel(args));

    for k = 1:numel(args)
        val = args{k};
        data(k) = asData(grid, val, [], anchor.RateBounds, ...
            "dpvar:InvalidConcatenation");
        sz(k, :) = data(k).MatrixSize;
        isScalar(k) = ~isa(val, "dpbase") && ...
            (isnumeric(val) || isa(val, "sdpvar")) && isscalar(val);
    end

    if dim == 2
        common = commonDim(sz(~isScalar, 1), "Horizontal");
        sz(isScalar, :) = [repmat(common, nnz(isScalar), 1), ones(nnz(isScalar), 1)];
        if any(sz(:, 1) ~= common)
            error("dpvar:InvalidConcatenation", ...
                "Horizontal dpvar concatenation requires equal row counts.");
        end
        outSize = [common, sum(sz(:, 2))];
    else
        common = commonDim(sz(~isScalar, 2), "Vertical");
        sz(isScalar, :) = [ones(nnz(isScalar), 1), repmat(common, nnz(isScalar), 1)];
        if any(sz(:, 2) ~= common)
            error("dpvar:InvalidConcatenation", ...
                "Vertical dpvar concatenation requires equal column counts.");
        end
        outSize = [sum(sz(:, 1)), common];
    end

    for k = find(isScalar)
        data(k).MatrixSize = sz(k, :);
        data(k).LocalValues = internal.mapVals(data(k).LocalValues, ...
            @(a) repmat(a, sz(k, :)), grid);
    end
end

function common = commonDim(vals, label)
    vals = vals(vals > 0);
    if isempty(vals)
        common = 1;
        return
    end
    common = vals(1);
    if any(vals ~= common)
        error("dpvar:InvalidConcatenation", ...
            "%s dpvar concatenation requires compatible block sizes.", label);
    end
end

function coeffs = catCell(dim, data, subs)
    nCoeff = numel(internal.cellGet(data(1).LocalValues, subs));
    coeffs = cell(1, nCoeff);
    for c = 1:nCoeff
        pieces = cell(1, numel(data));
        for k = 1:numel(data)
            one = internal.cellGet(data(k).LocalValues, subs);
            pieces{k} = one{c};
        end
        coeffs{c} = cat(dim, pieces{:});
    end
end
