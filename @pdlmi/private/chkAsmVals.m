function chkAsmVals(expr, vals, degree, mode)
    %CHKASMVALS Check generated coefficient-tree structure for assembly.
    %
    %   Syntax:
    %     chkAsmVals(expr, vals, degree, mode)
    %
    %   Arguments:
    %     expr   - Residual object supplying cells, npar, and MatrixSize.
    %     vals   - Generated nested coefficient tree.
    %     degree - Expected Bernstein degree of vals.
    %     mode   - "fast" checks one representative cell; "strict" checks all
    %              cells.
    %
    %   Output:
    %     This function has no output. It raises pdlmi:InvalidAssemblyData when
    %     generated coefficients do not match the expected shape contract.
    %
    %   Example:
    %     chkAsmVals(expr, elevated.LocalValues, targetDeg, "strict");
    %
    %   Generated assembly may come from elevation or Gram preprocessing.
    %   This guard checks structure before constraints are emitted, keeping
    %   fast mode cheap while preserving a strict audit path for generated
    %   coefficient trees.
    cells = expr.cells();
    if mode == "fast"
        indices = 1;
    else
        indices = 1:size(cells, 1);
    end
    nCoeff = prod(degree + 1);
    nRateRows = expr.NumRateRows;
    nRows = [];
    for c = indices
        leaf = helper.cellGet(vals, cells(c, :));
        if ~iscell(leaf) || size(leaf, 2) ~= nCoeff
            error("pdlmi:InvalidAssemblyData", ...
                "Generated coefficient rows do not match the assembly degree.");
        end
        if ~any(size(leaf, 1) == unique([1, nRateRows]))
            error("pdlmi:InvalidAssemblyData", ...
                "Generated coefficient rows must be ordinary or contain every rate vertex.");
        end
        if isempty(nRows)
            nRows = size(leaf, 1);
        elseif size(leaf, 1) ~= nRows
            error("pdlmi:InvalidAssemblyData", ...
                "Generated coefficient rows mix incompatible rate layouts.");
        end
        for k = 1:numel(leaf)
            val = leaf{k};
            if isa(val, "sdpvar")
                valid = ismatrix(val) && isreal(val) && ...
                    isequal(size(val), expr.MatrixSize);
            else
                valid = isnumeric(val) && isreal(val) && ...
                    all(isfinite(val), "all") && ...
                    isequal(size(val), expr.MatrixSize);
            end
            if ~valid
                error("pdlmi:InvalidAssemblyData", ...
                    "Generated coefficient payloads must match the residual matrix size.");
            end
        end
    end
end
