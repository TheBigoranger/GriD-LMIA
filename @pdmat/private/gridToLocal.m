function [sz, deg, vals, flat, cellSubs] = gridToLocal(src, vecs, optDeg, owner)
    %GRIDTOLOCAL Convert a global Bernstein coefficient grid to local cells.
    %
    %   Syntax:
    %     [sz, deg, vals, flat, cellSubs] = gridToLocal(src, vecs, optDeg, owner)
    %
    %   Arguments:
    %     src    - Global tensor cell grid of numeric coefficients.
    %     vecs   - Physical parameter grid vectors.
    %     optDeg - Optional scalar or per-parameter degree.
    %     owner  - Optional package name used in validation errors.
    %
    %   Output:
    %     sz       - Common coefficient-matrix size.
    %     deg      - Inferred or validated Bernstein degree.
    %     vals     - Nested physical-cell LocalValues tree.
    %     flat     - One flat coefficient leaf per cell row.
    %     cellSubs - Physical-cell subscripts matching flat.

    if nargin < 4
        owner = "pdmat";
    end
    owner = string(owner);

    helper.chk(src, owner + ":InvalidData", ...
        "Global coefficient data must be a nonempty cell array.", ...
        "cell", "nonempty");

    if ~isempty(optDeg)
        optDeg = helper.normalizeDegree(optDeg, numel(vecs), ...
            owner + ":InvalidDegree", "Degree");
    end

    nPar = numel(vecs);
    nCell = cellfun(@numel, vecs) - 1;
    dims = gridDims(src, nPar, owner);
    deg = gridDeg(dims, nCell, optDeg, owner);

    sz = scanMats(src(:), owner + ":InvalidData", ...
        "Each coefficient payload must be a nonempty finite real numeric matrix.");
    cellSubs = helper.combRows(arrayfun(@(n) 1:n, nCell, "UniformOutput", false));
    flat = cell(size(cellSubs, 1), 1);
    for r = 1:size(cellSubs, 1)
        flat{r} = coeffsFromGrid(src, cellSubs(r, :), deg);
    end

    vals = helper.mkNest(nCell, @(subs) coeffsFromGrid(src, subs, deg));
end

function dims = gridDims(src, nPar, owner)
    %GRIDDIMS Normalize the global cell-array dimensions to nPar axes.
    if nPar == 1
        dims = numel(src);
        return
    end

    dims = size(src);
    if numel(dims) < nPar
        dims(end + 1:nPar) = 1;
    end
    if numel(dims) > nPar && any(dims(nPar + 1:end) ~= 1)
        error(owner + ":InvalidData", ...
            "Global cell-grid data must have one cell dimension per parameter.");
    end
    dims = dims(1:nPar);
end

function deg = gridDeg(dims, nCell, optDeg, owner)
    %GRIDDEG Infer direction-wise degree or validate the requested one.
    if isempty(optDeg)
        raw = (dims - 1) ./ nCell;
        if any(raw ~= fix(raw))
            error(owner + ":InvalidDegree", ...
                "Global cell-grid size must equal (numCells .* Degree) + 1 in every parameter.");
        end
        deg = raw;
        return
    end

    deg = optDeg;
    if ~isequal(dims, nCell .* deg + 1)
        error(owner + ":InvalidDegree", ...
            "Global cell-grid size does not match the requested Degree.");
    end
end

function coeffs = coeffsFromGrid(src, cellSubs, deg)
    %COEFFSFROMGRID Extract one local leaf, retaining shared boundaries.
    lbls = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, deg, ...
        "UniformOutput", false));
    coeffs = cell(1, size(lbls, 1));
    for k = 1:size(lbls, 1)
        % Shared global grid boundaries become the matching local coefficient.
        idx = (cellSubs - 1) .* deg + lbls(k, :) + 1;
        sub = num2cell(idx);
        coeffs{k} = src{sub{:}};
    end
end
