function out = cat(dim, varargin)
    %CAT Concatenate coefficient-backed dpmat blocks along rows or columns.
    %
    %   Syntax:
    %     C = cat(1, A, B)
    %     C = cat(2, A, B)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     C = cat(2, A, A);

    if ~isnumeric(dim) || ~isscalar(dim) || dim ~= fix(dim) || dim < 1
        error("dpmat:InvalidConcatenation", "Concatenation dimension must be a positive integer scalar.");
    end
    if dim > 2
        error("dpmat:UnsupportedCatDimension", "dpmat only supports cat along dimensions 1 and 2.");
    end

    anchor = [];
    for k = 1:numel(varargin)
        if isa(varargin{k}, "dpmat")
            anchor = varargin{k};
            break
        end
    end
    if isempty(anchor)
        error("dpmat:InvalidConcatenation", "At least one concatenated value must be a dpmat.");
    end

    grid = anchor.mergeGrid("dpmat:MixedGrid", varargin{:});
    [data, sz] = catData(anchor, dim, varargin, grid);
    deg = max(arrayfun(@(d) d.Degree, data));

    for k = 1:numel(data)
        data(k).LocalValues = elevVals(anchor, data(k).LocalValues, data(k).Degree, deg, grid);
    end

    nCell = cellfun(@numel, grid) - 1;
    vals = internal.mkNest(nCell, @(subs) catCell(dim, data, subs));
    out = dpmat(grid, vals, Degree=deg);

    if ~isequal(size(out), sz)
        error("dpmat:InvalidConcatenation", "Internal dpmat concatenation size mismatch.");
    end
end

function [data, outSize] = catData(anchor, dim, args, grid)
    data = repmat(struct( ...
        "MatrixSize", [], ...
        "Degree", [], ...
        "LocalValues", [], ...
        "IsContinuous", []), 1, numel(args));
    raw = cell(1, numel(args));
    sz = zeros(numel(args), 2);
    isScalar = false(1, numel(args));

    for k = 1:numel(args)
        val = args{k};
        if isa(val, "dpmat")
            data(k) = asData(grid, val, [], "dpmat:InvalidConcatenation");
            sz(k, :) = data(k).MatrixSize;
        else
            helper.chk(val, "dpmat:InvalidConcatenation", ...
                "Numeric concatenation operands must be nonempty finite real matrices.", ...
                "numeric", "real", "finite", "matrix", "nonempty");
            raw{k} = val;
            sz(k, :) = size(val);
            isScalar(k) = isscalar(val);
        end
    end

    if dim == 2
        vals = sz(~isScalar, 1);
        vals = vals(vals > 0);
        if isempty(vals)
            common = 1;
        else
            common = vals(1);
            if any(vals ~= common)
                error("dpmat:InvalidConcatenation", ...
                    "Concatenated dpmat blocks have incompatible sizes.");
            end
        end
        sz(isScalar, :) = [repmat(common, nnz(isScalar), 1), ones(nnz(isScalar), 1)];
        if any(sz(:, 1) ~= common)
            error("dpmat:InvalidConcatenation", "Horizontal dpmat concatenation requires equal row counts.");
        end
        outSize = [common, sum(sz(:, 2))];
    else
        vals = sz(~isScalar, 2);
        vals = vals(vals > 0);
        if isempty(vals)
            common = 1;
        else
            common = vals(1);
            if any(vals ~= common)
                error("dpmat:InvalidConcatenation", ...
                    "Concatenated dpmat blocks have incompatible sizes.");
            end
        end
        sz(isScalar, :) = [ones(nnz(isScalar), 1), repmat(common, nnz(isScalar), 1)];
        if any(sz(:, 2) ~= common)
            error("dpmat:InvalidConcatenation", "Vertical dpmat concatenation requires equal column counts.");
        end
        outSize = [sum(sz(:, 1)), common];
    end

    for k = 1:numel(args)
        if ~isa(args{k}, "dpmat")
            mat = raw{k};
            if isscalar(mat)
                mat = repmat(mat, sz(k, :));
            end
            data(k).MatrixSize = sz(k, :);
            data(k).Degree = 0;
            nCell = cellfun(@numel, grid) - 1;
            data(k).LocalValues = internal.mkNest(nCell, @(~) {mat});
            data(k).IsContinuous = true;
        end
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
        coeffs{c} = builtin("cat", dim, pieces{:});
    end
end
