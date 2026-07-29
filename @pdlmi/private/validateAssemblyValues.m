function validateAssemblyValues(expr, vals, degree, validationMode)
    %VALIDATEASSEMBLYVALUES Check generated coefficient-tree structure.
    % Fast mode samples one structurally representative physical cell but still
    % checks every coefficient and active rate row in that cell. This sampling
    % never controls comparison classification or constraint generation, both
    % of which continue to traverse the complete residual.

    cells = expr.cells();
    if validationMode == "fast"
        cellIndices = 1;
    else
        cellIndices = 1:size(cells, 1);
    end
    expectedColumns = prod(degree + 1);
    expectedRows = [];
    for c = cellIndices
        leaf = helper.cellGet(vals, cells(c, :));
        if ~iscell(leaf) || size(leaf, 2) ~= expectedColumns
            error("pdlmi:InvalidAssemblyData", ...
                "Generated coefficient rows do not match the assembly degree.");
        end
        if ~any(size(leaf, 1) == [1, 2 ^ expr.npar()])
            error("pdlmi:InvalidAssemblyData", ...
                "Generated coefficient rows must be ordinary or contain every rate vertex.");
        end
        if isempty(expectedRows)
            expectedRows = size(leaf, 1);
        elseif size(leaf, 1) ~= expectedRows
            error("pdlmi:InvalidAssemblyData", ...
                "Generated coefficient rows mix incompatible rate layouts.");
        end
        for k = 1:numel(leaf)
            value = leaf{k};
            if isa(value, "sdpvar")
                valid = ismatrix(value) && isreal(value) && ...
                    isequal(size(value), expr.MatrixSize);
            else
                valid = isnumeric(value) && isreal(value) && ...
                    all(isfinite(value), "all") && ...
                    isequal(size(value), expr.MatrixSize);
            end
            if ~valid
                error("pdlmi:InvalidAssemblyData", ...
                    "Generated coefficient payloads must match the residual matrix size.");
            end
        end
    end
end
