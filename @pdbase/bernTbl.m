function tbl = bernTbl(obj, errId, valFcn, exprFcn, rateVerts, varargin)
    %BERNTBL Build a shared Bernstein coefficient inspection table.
    %
    %   Arguments:
    %     obj       - pdbase-derived object providing cells, labels, and coeffs.
    %     errId     - Identifier for selector or rate-row errors.
    %     valFcn    - Coefficient-to-table-value mapping.
    %     exprFcn   - Coefficient-to-expression-text mapping.
    %     rateVerts - Empty or one row per active rate vertex.
    %     varargin  - Optional cell selector and "oneLine" flag.
    %
    %   Output:
    %     T - Detailed coefficient table or one-line expression table.
    %
    %   Basis text uses alpha=(rho-lo)/(hi-lo). Local labels count powers of
    %   alpha, so label 0 is the lower/left endpoint in every cell. pdmat and
    %   pdvar supply their own coefficient-formatting callbacks.

    [cells, oneLine] = parseArgs(obj, errId, varargin{:});
    lbls = obj.lbls();
    basis = strings(size(lbls, 1), 1);
    for k = 1:size(lbls, 1)
        if all(obj.Degree == 0)
            basis(k) = "1";
            continue
        end

        loc = lbls(k, :);
        nPar = numel(loc);
        parts = strings(1, nPar);
        for p = 1:nPar
            if nPar == 1
                name = "alpha";
            else
                name = "alpha" + string(p);
            end
            parts(p) = oneBasis(name, obj.Degree(p), loc(p));
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
    %ORDINARYTBL Emit every matrix row without hiding complete coefficients.
    nMatRow = obj.MatrixSize(1);
    nTerm = size(cells, 1) * size(lbls, 1);
    nRow = nTerm * nMatRow;
    termIdx = zeros(nRow, 1);
    cellSubs = cell(nRow, 1);
    coeffSubs = cell(nRow, 1);
    locIdx = cell(nRow, 1);
    basisCol = strings(nRow, 1);
    isNode = false(nRow, 1);
    valsCol = cell(nRow, 1);

    row = 0;
    term = 0;
    for c = 1:size(cells, 1)
        cellSub = cells(c, :);
        vals = obj.coeffs(cellSub);
        for k = 1:size(lbls, 1)
            term = term + 1;
            [coeffSub, nodeFlag] = coeffInfo(obj, cellSub, lbls(k, :));
            for matRow = 1:nMatRow
                row = row + 1;
                termIdx(row) = term;
                cellSubs{row} = cellSub;
                coeffSubs{row} = coeffSub;
                locIdx{row} = lbls(k, :);
                basisCol(row) = basis(k);
                isNode(row) = nodeFlag;
                valsCol{row} = valFcn(vals{k}(matRow, :));
            end
        end
    end

    if nMatRow > 1
        termIdx = centeredMetadata(num2cell(termIdx), nMatRow, "number");
        cellSubs = centeredMetadata(cellSubs, nMatRow, "subscript");
        coeffSubs = centeredMetadata(coeffSubs, nMatRow, "subscript");
        locIdx = centeredMetadata(locIdx, nMatRow, "subscript");
        basisCol = centeredMetadata(num2cell(basisCol), nMatRow, "quoted");
        isNode = centeredMetadata(num2cell(isNode), nMatRow, "logical");
    end

    % Use MATLAB's ordinary table constructor; no pdmat/pdvar operands are passed.
    tbl = table(termIdx, cellSubs, coeffSubs, locIdx, basisCol, isNode, valsCol, ...
        'VariableNames', {'TermIndex', 'CellSubscript', ...
        'CoeffSubscript', 'LocalIndex', 'Basis', ...
        'IsPhysicalNode', 'Value'});
end

function tbl = rateTbl(obj, cells, lbls, basis, valFcn, rateVerts, errId)
    %RATETBL Emit matrix rows inside each cell/rate/coefficient group.
    nVert = size(rateVerts, 1);
    nMatRow = obj.MatrixSize(1);
    nTerm = size(cells, 1) * nVert * size(lbls, 1);
    nRow = nTerm * nMatRow;
    termIdx = zeros(nRow, 1);
    cellSubs = cell(nRow, 1);
    rateIdx = zeros(nRow, 1);
    rateCol = cell(nRow, 1);
    coeffSubs = cell(nRow, 1);
    locIdx = cell(nRow, 1);
    basisCol = strings(nRow, 1);
    isNode = false(nRow, 1);
    valsCol = cell(nRow, 1);

    row = 0;
    term = 0;
    for c = 1:size(cells, 1)
        cellSub = cells(c, :);
        vals = obj.coeffs(cellSub);
        if ~iscell(vals) || size(vals, 1) ~= nVert
            error(errId, ...
                "Rate-vertex coefficient rows must match the RateBounds vertices.");
        end
        for r = 1:nVert
            for k = 1:size(lbls, 1)
                term = term + 1;
                [coeffSub, nodeFlag] = coeffInfo(obj, cellSub, lbls(k, :));
                for matRow = 1:nMatRow
                    row = row + 1;
                    termIdx(row) = term;
                    cellSubs{row} = cellSub;
                    rateIdx(row) = r;
                    rateCol{row} = rateVerts(r, :);
                    coeffSubs{row} = coeffSub;
                    locIdx{row} = lbls(k, :);
                    basisCol(row) = basis(k);
                    isNode(row) = nodeFlag;
                    valsCol{row} = valFcn(vals{r, k}(matRow, :));
                end
            end
        end
    end

    if nMatRow > 1
        termIdx = centeredMetadata(num2cell(termIdx), nMatRow, "number");
        cellSubs = centeredMetadata(cellSubs, nMatRow, "subscript");
        rateIdx = centeredMetadata(num2cell(rateIdx), nMatRow, "number");
        rateCol = centeredMetadata(rateCol, nMatRow, "subscript");
        coeffSubs = centeredMetadata(coeffSubs, nMatRow, "subscript");
        locIdx = centeredMetadata(locIdx, nMatRow, "subscript");
        basisCol = centeredMetadata(num2cell(basisCol), nMatRow, "quoted");
        isNode = centeredMetadata(num2cell(isNode), nMatRow, "logical");
    end

    tbl = table(termIdx, cellSubs, rateIdx, rateCol, coeffSubs, ...
        locIdx, basisCol, isNode, valsCol, ...
        'VariableNames', {'TermIndex', 'CellSubscript', ...
        'RateVertexIndex', 'RateVertex', 'CoeffSubscript', ...
        'LocalIndex', 'Basis', 'IsPhysicalNode', 'Value'});
end

function tbl = printOneLine(obj, cells, basis, exprFcn, rateVerts, hasRate, errId)
    %PRINTONELINE Build one expression row per cell and active rate vertex.
    nMatRow = obj.MatrixSize(1);
    if hasRate
        nVert = size(rateVerts, 1);
        nRow = size(cells, 1) * nVert * nMatRow;
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
                for matRow = 1:nMatRow
                    row = row + 1;
                    cellSubs{row} = cellSub;
                    rateIdx(row) = r;
                    rateCol{row} = rateVerts(r, :);
                    exprs(row) = rowExpr( ...
                        basis, vals(r, :), exprFcn, matRow);
                end
            end
        end

        if nMatRow > 1
            cellSubs = centeredMetadata(cellSubs, nMatRow, "subscript");
            rateIdx = centeredMetadata(num2cell(rateIdx), nMatRow, "number");
            rateCol = centeredMetadata(rateCol, nMatRow, "subscript");
        end

        tbl = table(cellSubs, rateIdx, rateCol, exprs, ...
            'VariableNames', {'CellSubscript', 'RateVertexIndex', ...
            'RateVertex', 'Expression'});
        return
    end

    nRow = size(cells, 1) * nMatRow;
    cellSubs = cell(nRow, 1);
    exprs = strings(nRow, 1);
    row = 0;
    for c = 1:size(cells, 1)
        cellSub = cells(c, :);
        vals = obj.coeffs(cellSub);
        for matRow = 1:nMatRow
            row = row + 1;
            cellSubs{row} = cellSub;
            exprs(row) = rowExpr(basis, vals, exprFcn, matRow);
        end
    end

    if nMatRow > 1
        cellSubs = centeredMetadata(cellSubs, nMatRow, "subscript");
    end

    tbl = table(cellSubs, exprs, ...
        'VariableNames', {'CellSubscript', 'Expression'});
end

function expr = rowExpr(basis, vals, exprFcn, matRow)
    %ROWEXPR Join one ordered coefficient row into Bernstein expression text.
    terms = strings(1, numel(vals));
    for k = 1:numel(vals)
        val = exprFcn(vals{k}(matRow, :));
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
    if all(obj.Degree == 0)
        coeffSub = ones(size(cellSub));
        nodeFlag = true;
    else
        coeffSub = (cellSub - 1) .* obj.Degree + loc + 1;
        positive = obj.Degree > 0;
        nodeFlag = all(~positive | ...
            mod(coeffSub - 1, max(obj.Degree, 1)) == 0);
    end
end

function col = centeredMetadata(values, nMatRow, kind)
    %CENTEREDMETADATA Show group metadata once beside expanded matrix rows.
    nRow = numel(values);
    text = strings(nRow, 1);
    center = floor(nMatRow / 2) + 1;
    for row = center:nMatRow:nRow
        value = values{row};
        switch kind
            case "number"
                text(row) = string(value);
            case "subscript"
                if isscalar(value)
                    text(row) = "{[" + string(value) + "]}";
                else
                    text(row) = "{" + string(mat2str(value)) + "}";
                end
            case "quoted"
                text(row) = """" + string(value) + """";
            case "logical"
                text(row) = string(mat2str(value));
        end
    end

    % Character table variables render empty rows as whitespace, unlike
    % missing numeric, string, or cell values, which show visible markers.
    col = char(text);
end

function [cells, oneLine] = parseArgs(obj, errId, varargin)
    %PARSEARGS Normalize the optional cell selector and oneLine flag.
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
    % Labels count alpha powers, preserving lower-to-upper storage order.
    powOneMinus = deg - idx;
    powAlpha = idx;
    parts = strings(1, 0);
    scale = nchoosek(deg, idx);
    if powOneMinus > 0
        base = "(1-" + name + ")";
        if powOneMinus == 1
            parts(end + 1) = base;
        else
            parts(end + 1) = base + "^" + string(powOneMinus);
        end
    end
    if powAlpha > 0
        if powAlpha == 1
            parts(end + 1) = name;
        else
            parts(end + 1) = name + "^" + string(powAlpha);
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
