function cons = mkCoeffCons(expr, relation, usePolya, pDeg)
    %MKCOEFFCONS Assemble direct or elevated coefficient constraints.
    %   Each physical cell and active rate row produces one semidefinite
    %   constraint per local Bernstein coefficient. Pólya selection changes
    %   only the coefficient degree through exact elevation.

    if usePolya
        vals = expr.elevVals(pDeg);
    else
        vals = expr.LocalValues;
    end

    cells = expr.cells();
    cons = {};
    zero = zeros(expr.MatrixSize);
    for c = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(c, :));
        for row = 1:size(coeffs, 1)
            for k = 1:size(coeffs, 2)
                mat = coeffs{row, k};
                if size(mat, 1) ~= size(mat, 2)
                    error("pdlmi:InvalidMatrixSize", ...
                        "PD-LMI constraints require square coefficient matrices.");
                end
                if isa(mat, "sdpvar")
                    symmetric = ishermitian(mat);
                else
                    symmetric = norm(mat - mat', inf) <= 1e-10;
                end
                if ~symmetric
                    error("pdlmi:NonSymmetricExpression", ...
                        "PD-LMI constraints require symmetric or Hermitian coefficient matrices.");
                end

                % Each row is a rate vertex when rhodiff produced rate rows;
                % ordinary expressions simply have one row.
                if relation == "<="
                    cons{end + 1, 1} = mat <= zero; %#ok<AGROW>
                else
                    cons{end + 1, 1} = mat >= zero; %#ok<AGROW>
                end
            end
        end
    end
end
