function out = cat(dim, varargin)
    %CAT Concatenate pdvar-compatible coefficient blocks along rows or columns.
    %
    %   Syntax:
    %     C = cat(1, P, Q)
    %     C = cat(2, P, A)
    %
    %   Output:
    %     C - pdvar expression formed by coefficient-wise block concatenation.
    %
    %   Example:
    %     P = pdvar(2, 1, {[0 1]});
    %     C = cat(2, P, ones(2, 1));

    if ~isnumeric(dim) || ~isscalar(dim) || dim ~= fix(dim) || dim < 1
        error("pdvar:InvalidConcatenation", ...
            "Concatenation dimension must be a positive integer scalar.");
    end
    if dim > 2
        error("pdvar:UnsupportedCatDimension", ...
            "pdvar only supports cat along dimensions 1 and 2.");
    end

    anchor = pickAnchor("pdvar:InvalidConcatenation", varargin);
    grid = anchor.mergeGrid("pdvar:MixedGrid", varargin{:});
    rb = anchor.pickRateBounds("pdvar:InvalidConcatenation", varargin{:});
    [data, sz] = catData(dim, varargin, grid, rb);
    deg = max(vertcat(data.Degree), [], 1);

    data = pdbase.elevData(data, deg, grid, "fast");

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) catCell(anchor, dim, data, subs));
    hasDec = any(arrayfun(@(d) d.ContainsDecision, data));
    numRateRows = max(arrayfun(@(d) d.NumRateRows, data));

    out = pdvar(mkCtorState(grid, sz, deg, vals, hasDec, rb, ...
        "expression", all(arrayfun(@(d) d.IsContinuous, data)), "fast", ...
        numRateRows));
    if ~isequal(size(out), sz)
        error("pdvar:InvalidConcatenation", ...
            "Internal pdvar concatenation size mismatch.");
    end
end

function [data, outSize] = catData(dim, args, grid, rb)
    %CATDATA Promote blocks, broadcast scalars, and infer concatenated size.
    data = repmat(struct( ...
        "MatrixSize", [], ...
        "Degree", [], ...
        "LocalValues", [], ...
        "ContainsDecision", [], ...
        "IsContinuous", [], ...
        "NumRateRows", []), 1, numel(args));
    sz = zeros(numel(args), 2);
    isScalar = false(1, numel(args));

    for k = 1:numel(args)
        val = args{k};
        data(k) = normOperand(grid, val, [], rb, ...
            "pdvar:InvalidConcatenation");
        sz(k, :) = data(k).MatrixSize;
        isScalar(k) = ~isa(val, "pdbase") && ...
            (isnumeric(val) || isa(val, "sdpvar")) && isscalar(val);
    end

    if dim == 2
        common = commonDim(sz(~isScalar, 1), "Horizontal");
        sz(isScalar, :) = [repmat(common, nnz(isScalar), 1), ones(nnz(isScalar), 1)];
        if any(sz(:, 1) ~= common)
            error("pdvar:InvalidConcatenation", ...
                "Horizontal pdvar concatenation requires equal row counts.");
        end
        outSize = [common, sum(sz(:, 2))];
    else
        common = commonDim(sz(~isScalar, 2), "Vertical");
        sz(isScalar, :) = [ones(nnz(isScalar), 1), repmat(common, nnz(isScalar), 1)];
        if any(sz(:, 2) ~= common)
            error("pdvar:InvalidConcatenation", ...
                "Vertical pdvar concatenation requires equal column counts.");
        end
        outSize = [sum(sz(:, 1)), common];
    end

    for k = find(isScalar)
        data(k).MatrixSize = sz(k, :);
        data(k).LocalValues = pdbase.mapVals(data(k).LocalValues, ...
            @(a) repmat(a, sz(k, :)), grid);
    end
end

function common = commonDim(vals, label)
    %COMMONDIM Return the shared non-scalar block dimension or fail.
    vals = vals(vals > 0);
    if isempty(vals)
        common = 1;
        return
    end
    common = vals(1);
    if any(vals ~= common)
        error("pdvar:InvalidConcatenation", ...
            "%s pdvar concatenation requires compatible block sizes.", label);
    end
end

function coeffs = catCell(anchor, dim, data, subs)
    %CATCELL Concatenate one cell after ordinary/rate row alignment.
    leaves = cell(1, numel(data));
    for k = 1:numel(data)
        leaves{k} = helper.cellGet(data(k).LocalValues, subs);
    end
    % rhodiff leaves have one row per rate vertex; ordinary leaves have one
    % row and broadcast across those vertices before block assembly.
    coeffs = anchor.joinRateRows(leaves, @(parts) cat(dim, parts{:}), ...
        "pdvar:InvalidCoefficientRows");
end
