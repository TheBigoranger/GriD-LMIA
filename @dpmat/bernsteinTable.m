function tbl = bernsteinTable(obj, varargin)
    %BERNSTEINTABLE Return a command-line Bernstein coefficient table for dpmat.
    %
    %   Syntax:
    %     T = bernsteinTable(A)
    %     T = bernsteinTable(A, cellSubs)
    %     T = bernsteinTable(A, "oneLine")
    %     T = bernsteinTable(A, cellSubs, "oneLine")
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     T = bernsteinTable(A);
    %     T1 = bernsteinTable(A, 1, "oneLine");

    if obj.SourceSummary == "function"
        error("dpmat:FunctionOnlyBernsteinTable", ...
            "Function-only dpmat objects do not have Bernstein coefficient evidence to tabulate.");
    end

    [cells, oneLine] = parseArgs(obj, varargin{:});
    lbls = obj.lbls();

    if oneLine
        tbl = oneLineTbl(obj, cells, lbls);
        return
    end

    nRow = size(cells, 1) * size(lbls, 1);
    termIdx = (1:nRow).';
    cellSubs = cell(nRow, 1);
    coeffSubs = cell(nRow, 1);
    locIdx = cell(nRow, 1);
    basis = strings(nRow, 1);
    isNode = false(nRow, 1);
    valsCol = cell(nRow, 1);

    row = 0;
    for c = 1:size(cells, 1)
        cellSub = cells(c, :);
        vals = obj.coeffs(cellSub);
        for k = 1:size(lbls, 1)
            row = row + 1;
            loc = lbls(k, :);
            % Map the cell-local Bernstein label back to the global
            % coefficient subscript used by coeffs and node diagnostics.
            if obj.Degree == 0
                coeffSub = ones(size(cellSub));
                nodeFlag = true;
            else
                coeffSub = (cellSub - 1) .* obj.Degree + loc + 1;
                nodeFlag = all(mod(coeffSub - 1, obj.Degree) == 0);
            end
            cellSubs{row} = cellSub;
            coeffSubs{row} = coeffSub;
            locIdx{row} = loc;
            basis(row) = localBasis(obj.Degree, loc);
            isNode(row) = nodeFlag;
            valsCol{row} = vals{k};
        end
    end

    % Use MATLAB's ordinary table constructor; no dpmat operands are passed.
    tbl = table(termIdx, cellSubs, coeffSubs, locIdx, basis, isNode, valsCol, ...
        'VariableNames', {'TermIndex', 'CellSubscript', ...
        'CoeffSubscript', 'LocalIndex', 'Basis', ...
        'IsPhysicalNode', 'Value'});
end

function [cells, oneLine] = parseArgs(obj, varargin)
    cells = obj.cells();
    oneLine = false;
    hasCell = false;

    for k = 1:numel(varargin)
        arg = varargin{k};
        if isText(arg)
            if strcmpi(string(arg), "oneLine")
                oneLine = true;
            else
                error("dpmat:InvalidBernsteinTableInput", ...
                    "The only text option supported by bernsteinTable is ""oneLine"".");
            end
        elseif ~hasCell
            cells = oneCell(obj, arg);
            hasCell = true;
        else
            error("dpmat:InvalidBernsteinTableInput", ...
                "bernsteinTable accepts at most one physical-cell selector and the optional ""oneLine"" mode.");
        end
    end
end

function cells = oneCell(obj, arg)
    if iscell(arg)
        cells = cellfun(@double, arg);
    else
        cells = double(arg);
    end
    cells = reshape(cells, 1, []);

    % Reuse the public coefficient accessor for nested LocalValues indexing
    % validation, so bernsteinTable(A, cellSubs) rejects the same hypercubes as coeffs.
    obj.coeffs(cells);
end

function tf = isText(arg)
    tf = (isstring(arg) && isscalar(arg)) || (ischar(arg) && isrow(arg));
end

function tbl = oneLineTbl(obj, cells, lbls)
    cellSubs = cell(size(cells, 1), 1);
    exprs = strings(size(cells, 1), 1);

    for c = 1:size(cells, 1)
        cellSub = cells(c, :);
        vals = obj.coeffs(cellSub);
        cellSubs{c} = cellSub;
        exprs(c) = oneLineExpr(obj.Degree, lbls, vals);
    end

    tbl = table(cellSubs, exprs, ...
        'VariableNames', {'CellSubscript', 'Expression'});
end

function expr = oneLineExpr(deg, lbls, vals)
    terms = strings(1, size(lbls, 1));
    for k = 1:size(lbls, 1)
        % localBasis includes the Bernstein nchoosek scale, so interior
        % one-line terms keep the same convention as the coefficient table.
        basis = localBasis(deg, lbls(k, :));
        val = mat2str(vals{k});
        if basis == "1"
            terms(k) = val;
        else
            terms(k) = basis + "*" + string(val);
        end
    end
    expr = strjoin(terms, " + ");
end

function basis = localBasis(deg, loc)
    if deg == 0
        basis = "1";
        return
    end

    nPar = numel(loc);
    parts = strings(1, nPar);
    for p = 1:nPar
        if nPar == 1
            name = "a";
        else
            name = "a" + string(p);
        end
        parts(p) = oneBasis(name, deg, loc(p));
    end
    basis = strjoin(parts, " * ");
end

function txt = oneBasis(name, deg, idx)
    % lbls() uses local indices 0:deg; preserve that ordering in text so
    % table rows and one-line expressions match coefficient storage.
    powA = deg - idx;
    powB = idx;
    parts = strings(1, 0);
    scale = nchoosek(deg, idx);
    if powA > 0
        parts(end + 1) = powText(name, powA);
    end
    if powB > 0
        parts(end + 1) = powText("(1-" + name + ")", powB);
    end

    if isempty(parts)
        txt = "1";
    elseif scale == 1
        txt = strjoin(parts, "");
    else
        txt = string(scale) + strjoin(parts, "");
    end
end

function txt = powText(base, pow)
    if pow == 1
        txt = base;
    else
        txt = base + "^" + string(pow);
    end
end
