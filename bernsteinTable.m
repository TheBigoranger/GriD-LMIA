function tbl = bernsteinTable(obj)
    %BERNSTEINTABLE Return coefficient-grid metadata for inspection.
    %
    %   TBL = BERNSTEINTABLE(OBJ) returns one table row per Bernstein coefficient,
    %   including coefficient subscript, local basis string, cell subscript, local
    %   index, physical-node flag, and stored value.
    %
    %   Example:
    %       tbl = bernsteinTable(P);
    %
    %   Scope: debugging and audit helper for dpvar and coefficient-backed dpmat
    %   objects. It does not evaluate the expression or build constraints.

    narginchk(1, 1)
    [grid, values] = bernsteinGrid(obj);
    [~, subscripts] = getGridMap(grid.Vectors);
    numRows = size(subscripts, 1);
    coeffSubscript = cell(numRows, 1);
    basis = strings(numRows, 1);
    cellSubscript = cell(numRows, 1);
    localIndex = cell(numRows, 1);
    coefficientValue = cell(numRows, 1);
    isPhysicalNode = false(numRows, 1);

    for row = 1:numRows
        sub = subscripts(row, :);
        coeffSubscript{row} = sub;
        [cellSub, localSub, physical] = localMetadata(grid.PhysicalGridInfo, grid.Degree, sub);
        % Coordinates stay in bernsteinGrid; Basis exposes the local
        % Bernstein monomial that owns this coefficient.
        basis(row) = localBasisString(grid.Degree, localSub);
        cellSubscript{row} = cellSub;
        localIndex{row} = localSub;
        isPhysicalNode(row) = physical;
        valueSub = num2cell(sub);
        coefficientValue{row} = values{valueSub{:}};
    end

    termIndex = (1:numRows).';
    tbl = table(termIndex, coeffSubscript, basis, isPhysicalNode, ...
        cellSubscript, localIndex, coefficientValue, ...
        'VariableNames', {'TermIndex', 'CoeffSubscript', 'Basis', ...
        'IsPhysicalNode', 'CellSubscript', 'LocalIndex', 'Value'});
end

function [cellSub, localSub, physical] = localMetadata(gridInfo, degree, sub)
    %LOCALMETADATA Map an expanded coefficient subscript to local metadata.
    %
    %   [CELLSUB, LOCALSUB, PHYSICAL] = LOCALMETADATA(GRIDINFO, DEGREE, SUB)
    %   identifies the owning physical cell and local Bernstein index.
    %
    %   Example:
    %       [cellSub, localSub, physical] = localMetadata(gridInfo, 2, [3 1]);
    %
    %   Scope: local bernsteinTable helper for tabular diagnostics.
    if degree == 0
        cellSub = ones(1, numel(sub));
        localSub = zeros(1, numel(sub));
        physical = true;
        return
    end

    cellSub = zeros(size(sub));
    localSub = zeros(size(sub));
    physical = true;
    for dim = 1:numel(sub)
        idx = sub(dim);
        physical = physical && mod(idx - 1, degree) == 0;
        % The final expanded node is the right face of the last physical cell,
        % not the first node of a nonexistent next cell.
        if idx == degree * (gridInfo.NumNodes(dim) - 1) + 1
            cellSub(dim) = gridInfo.NumNodes(dim) - 1;
            localSub(dim) = degree;
        else
            cellSub(dim) = floor((idx - 1) / degree) + 1;
            localSub(dim) = mod(idx - 1, degree);
        end
    end
end

function basis = localBasisString(degree, localSub)
    %LOCALBASISSTRING Format one tensor-product Bernstein basis label.
    %
    %   BASIS = LOCALBASISSTRING(DEGREE, LOCALSUB) returns strings such as
    %   "a^2(1-a)" or "a1 * (1-a2)".
    %
    %   Example:
    %       basis = localBasisString(3, 1);
    %
    %   Scope: local bernsteinTable helper for human-readable coefficient labels.
    if degree == 0
        basis = "1";
        return
    end

    numDims = numel(localSub);
    factors = strings(1, numDims);
    for dim = 1:numDims
        if numDims == 1
            alphaName = "a";
        else
            alphaName = "a" + string(dim);
        end
        factors(dim) = localOneDimBasis(alphaName, degree, localSub(dim));
    end
    basis = strjoin(factors, " * ");
end

function basis = localOneDimBasis(alphaName, degree, localIndex)
    %LOCALONEDIMBASIS Format one one-dimensional Bernstein basis factor.
    %
    %   BASIS = LOCALONEDIMBASIS(ALPHANAME, DEGREE, LOCALINDEX) returns the
    %   binomial-scaled factor for one parameter dimension.
    %
    %   Example:
    %       basis = localOneDimBasis("a", 3, 1);
    %
    %   Scope: local formatting helper used by localBasisString.
    alphaPower = degree - localIndex;
    complementPower = localIndex;
    factors = strings(1, 0);
    coefficient = nchoosek(degree, localIndex);

    if alphaPower > 0
        factors(end + 1) = powerString(alphaName, alphaPower);
    end
    if complementPower > 0
        factors(end + 1) = powerString("(1-" + alphaName + ")", complementPower);
    end

    if isempty(factors)
        basis = "1";
    elseif coefficient == 1
        basis = strjoin(factors, "");
    else
        basis = string(coefficient) + strjoin(factors, "");
    end
end

function text = powerString(base, power)
    %POWERSTRING Format BASE or BASE^POWER.
    %
    %   TEXT = POWERSTRING(BASE, POWER) omits the exponent when POWER is one.
    %
    %   Example:
    %       text = powerString("a", 2);
    %
    %   Scope: local bernsteinTable string-formatting helper.
    if power == 1
        text = base;
    else
        text = base + "^" + string(power);
    end
end
