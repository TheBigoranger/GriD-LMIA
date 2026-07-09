function tbl = bernTbl(obj, errId, valFcn, exprFcn, rateVerts, varargin)
    %BERNTBL Build a Bernstein coefficient inspection table.
    %
    %   Syntax:
    %     T = helper.bernTbl(obj, errId, valFcn, exprFcn, rateVerts)
    %     T = helper.bernTbl(..., cellSubs)
    %     T = helper.bernTbl(..., "oneLine")
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     T = helper.bernTbl(A, "demo:Invalid", @(x) x, ...
    %         @(x) string(mat2str(x)), []);

    [cells, oneLine] = parseArgs(obj, errId, varargin{:});
    lbls = obj.lbls();
    basis = strings(size(lbls, 1), 1);
    for k = 1:size(lbls, 1)
        if obj.Degree == 0
            basis(k) = "1";
            continue
        end

        loc = lbls(k, :);
        nPar = numel(loc);
        parts = strings(1, nPar);
        for p = 1:nPar
            if nPar == 1
                name = "a";
            else
                name = "a" + string(p);
            end
            parts(p) = oneBasis(name, obj.Degree, loc(p));
        end
        basis(k) = strjoin(parts, " * ");
    end
    hasRate = ~isempty(rateVerts);

    if oneLine
        tbl = printOneLine(obj, cells, basis, exprFcn, rateVerts, hasRate, errId);
        return
    end

    if hasRate
        tbl = rateTbl(obj, cells, lbls, basis, valFcn, rateVerts, errId);
    else
        tbl = ordinaryTbl(obj, cells, lbls, basis, valFcn);
    end
end

function tbl = ordinaryTbl(obj, cells, lbls, basis, valFcn)
    nRow = size(cells, 1) * size(lbls, 1);
    termIdx = (1:nRow).';
    cellSubs = cell(nRow, 1);
    coeffSubs = cell(nRow, 1);
    locIdx = cell(nRow, 1);
    basisCol = strings(nRow, 1);
    isNode = false(nRow, 1);
    valsCol = cell(nRow, 1);

    row = 0;
    for c = 1:size(cells, 1)
        cellSub = cells(c, :);
        vals = obj.coeffs(cellSub);
        for k = 1:size(lbls, 1)
            row = row + 1;
            [coeffSub, nodeFlag] = coeffInfo(obj, cellSub, lbls(k, :));
            cellSubs{row} = cellSub;
            coeffSubs{row} = coeffSub;
            locIdx{row} = lbls(k, :);
            basisCol(row) = basis(k);
            isNode(row) = nodeFlag;
            valsCol{row} = valFcn(vals{k});
        end
    end

    % Use MATLAB's ordinary table constructor; no dpmat/dpvar operands are passed.
    tbl = table(termIdx, cellSubs, coeffSubs, locIdx, basisCol, isNode, valsCol, ...
        'VariableNames', {'TermIndex', 'CellSubscript', ...
        'CoeffSubscript', 'LocalIndex', 'Basis', ...
        'IsPhysicalNode', 'Value'});
end

function tbl = rateTbl(obj, cells, lbls, basis, valFcn, rateVerts, errId)
    nVert = size(rateVerts, 1);
    nRow = size(cells, 1) * nVert * size(lbls, 1);
    termIdx = (1:nRow).';
    cellSubs = cell(nRow, 1);
    rateIdx = zeros(nRow, 1);
    rateCol = cell(nRow, 1);
    coeffSubs = cell(nRow, 1);
    locIdx = cell(nRow, 1);
    basisCol = strings(nRow, 1);
    isNode = false(nRow, 1);
    valsCol = cell(nRow, 1);

    row = 0;
    for c = 1:size(cells, 1)
        cellSub = cells(c, :);
        vals = obj.coeffs(cellSub);
        if ~iscell(vals) || size(vals, 1) ~= nVert
            error(errId, ...
                "Rate-vertex coefficient rows must match the RateBounds vertices.");
        end
        for r = 1:nVert
            for k = 1:size(lbls, 1)
                row = row + 1;
                [coeffSub, nodeFlag] = coeffInfo(obj, cellSub, lbls(k, :));
                cellSubs{row} = cellSub;
                rateIdx(row) = r;
                rateCol{row} = rateVerts(r, :);
                coeffSubs{row} = coeffSub;
                locIdx{row} = lbls(k, :);
                basisCol(row) = basis(k);
                isNode(row) = nodeFlag;
                valsCol{row} = valFcn(vals{r, k});
            end
        end
    end

    tbl = table(termIdx, cellSubs, rateIdx, rateCol, coeffSubs, ...
        locIdx, basisCol, isNode, valsCol, ...
        'VariableNames', {'TermIndex', 'CellSubscript', ...
        'RateVertexIndex', 'RateVertex', 'CoeffSubscript', ...
        'LocalIndex', 'Basis', 'IsPhysicalNode', 'Value'});
end

function tbl = printOneLine(obj, cells, basis, exprFcn, rateVerts, hasRate, errId)
    if hasRate
        nVert = size(rateVerts, 1);
        nRow = size(cells, 1) * nVert;
        cellSubs = cell(nRow, 1);
        rateIdx = zeros(nRow, 1);
        rateCol = cell(nRow, 1);
        exprs = strings(nRow, 1);

        row = 0;
        for c = 1:size(cells, 1)
            cellSub = cells(c, :);
            vals = obj.coeffs(cellSub);
            if ~iscell(vals) || size(vals, 1) ~= nVert
                error(errId, ...
                    "Rate-vertex coefficient rows must match the RateBounds vertices.");
            end
            for r = 1:nVert
                row = row + 1;
                cellSubs{row} = cellSub;
                rateIdx(row) = r;
                rateCol{row} = rateVerts(r, :);
                exprs(row) = rowExpr(basis, vals(r, :), exprFcn);
            end
        end

        tbl = table(cellSubs, rateIdx, rateCol, exprs, ...
            'VariableNames', {'CellSubscript', 'RateVertexIndex', ...
            'RateVertex', 'Expression'});
        return
    end

    cellSubs = cell(size(cells, 1), 1);
    exprs = strings(size(cells, 1), 1);
    for c = 1:size(cells, 1)
        cellSub = cells(c, :);
        vals = obj.coeffs(cellSub);
        cellSubs{c} = cellSub;
        exprs(c) = rowExpr(basis, vals, exprFcn);
    end

    tbl = table(cellSubs, exprs, ...
        'VariableNames', {'CellSubscript', 'Expression'});
end

function expr = rowExpr(basis, vals, exprFcn)
    terms = strings(1, numel(vals));
    for k = 1:numel(vals)
        val = exprFcn(vals{k});
        if basis(k) == "1"
            terms(k) = val;
        else
            terms(k) = basis(k) + "*" + val;
        end
    end
    expr = strjoin(terms, " + ");
end

function [coeffSub, nodeFlag] = coeffInfo(obj, cellSub, loc)
    % Map the local Bernstein label back to the global coefficient subscript
    % used by coeffs and physical-node diagnostics.
    if obj.Degree == 0
        coeffSub = ones(size(cellSub));
        nodeFlag = true;
    else
        coeffSub = (cellSub - 1) .* obj.Degree + loc + 1;
        nodeFlag = all(mod(coeffSub - 1, obj.Degree) == 0);
    end
end

function [cells, oneLine] = parseArgs(obj, errId, varargin)
    cells = obj.cells();
    oneLine = false;
    hasCell = false;

    for k = 1:numel(varargin)
        arg = varargin{k};
        if (isstring(arg) && isscalar(arg)) || (ischar(arg) && isrow(arg))
            if strcmpi(string(arg), "oneLine")
                oneLine = true;
            else
                error(errId, ...
                    "The only text option supported by bernsteinTable is ""oneLine"".");
            end
        elseif ~hasCell
            if iscell(arg)
                cells = cellfun(@double, arg);
            else
                cells = double(arg);
            end
            cells = reshape(cells, 1, []);

            % Reuse the public coefficient accessor so the table accepts
            % exactly the same nested LocalValues physical cells as coeffs().
            obj.coeffs(cells);
            hasCell = true;
        else
            error(errId, ...
                "bernsteinTable accepts at most one physical-cell selector and the optional ""oneLine"" mode.");
        end
    end
end

function txt = oneBasis(name, deg, idx)
    % lbls() uses local indices 0:deg; keep text in that storage order.
    powA = deg - idx;
    powB = idx;
    parts = strings(1, 0);
    scale = nchoosek(deg, idx);
    if powA > 0
        if powA == 1
            parts(end + 1) = name;
        else
            parts(end + 1) = name + "^" + string(powA);
        end
    end
    if powB > 0
        base = "(1-" + name + ")";
        if powB == 1
            parts(end + 1) = base;
        else
            parts(end + 1) = base + "^" + string(powB);
        end
    end

    if isempty(parts)
        txt = "1";
    elseif scale == 1
        txt = strjoin(parts, "");
    else
        txt = string(scale) + strjoin(parts, "");
    end
end
