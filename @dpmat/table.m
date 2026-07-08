function tbl = table(obj)
    %TABLE Return a command-line Bernstein coefficient table for dpmat.
    %
    %   Syntax:
    %     T = table(A)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     T = table(A);

    if obj.SourceSummary == "function"
        error("dpmat:FunctionOnlyTable", ...
            "Function-only dpmat objects do not have Bernstein coefficient evidence to tabulate.");
    end

    cells = obj.cells();
    lbls = obj.lbls();
    nRow = size(cells, 1) * size(lbls, 1);
    termIndex = (1:nRow).';
    cellSubscript = cell(nRow, 1);
    coeffSubscript = cell(nRow, 1);
    localIndex = cell(nRow, 1);
    basis = strings(nRow, 1);
    isPhysicalNode = false(nRow, 1);
    value = cell(nRow, 1);

    row = 0;
    for c = 1:size(cells, 1)
        cellSub = cells(c, :);
        vals = obj.coeffs(cellSub);
        for k = 1:size(lbls, 1)
            row = row + 1;
            loc = lbls(k, :);
            coeffSub = expandedSub(cellSub, loc, obj.Degree);
            cellSubscript{row} = cellSub;
            coeffSubscript{row} = coeffSub;
            localIndex{row} = loc;
            basis(row) = localBasis(obj.Degree, loc);
            isPhysicalNode(row) = physicalNode(coeffSub, obj.Degree);
            value{row} = vals{k};
        end
    end

    % Use MATLAB's ordinary table constructor; no dpmat operands are passed.
    tbl = table(termIndex, cellSubscript, coeffSubscript, localIndex, ...
        basis, isPhysicalNode, value, ...
        'VariableNames', {'TermIndex', 'CellSubscript', ...
        'CoeffSubscript', 'LocalIndex', 'Basis', ...
        'IsPhysicalNode', 'Value'});
end

function sub = expandedSub(cellSub, loc, deg)
    if deg == 0
        sub = ones(size(cellSub));
    else
        sub = (cellSub - 1) .* deg + loc + 1;
    end
end

function tf = physicalNode(sub, deg)
    if deg == 0
        tf = true;
    else
        tf = all(mod(sub - 1, deg) == 0);
    end
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
