function cons = mkCoeffCons(expr, relation, usePolya, pDeg, mode)
    %MKCOEFFCONS Assemble direct or elevated coefficient constraints.
    %
    %   Syntax:
    %     cons = mkCoeffCons(expr, relation, usePolya, pDeg, mode)
    %
    %   Arguments:
    %     expr     - pdvar residual with local Bernstein coefficients.
    %     relation - Normalized "<=", ">=", or "==" relation.
    %     usePolya - True to elevate coefficients before assembly.
    %     pDeg     - Uniform Pólya elevation increment when usePolya is true.
    %     mode     - "semidefinite", "elementwise", or "equality".
    %
    %   Output:
    %     cons - Cell column of YALMIP coefficient constraints.
    %
    %   Each physical cell and active rate row produces one constraint per
    %   local coefficient. Pólya selection changes only the coefficient degree
    %   through exact elevation. Equality vectorizes each coefficient and omits
    %   a constraint only when numeric zero is proven.

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
                % Each row is a rate vertex when rhodiff produced rate rows;
                % ordinary expressions simply have one row.
                if mode == "equality"
                    % Proven numeric-zero identities need no YALMIP constraint.
                    if helper.isZero(mat, "num")
                        continue
                    end
                    cons{end + 1, 1} = mat(:) == 0; %#ok<AGROW>
                elseif mode == "elementwise"
                    if relation == "<="
                        cons{end + 1, 1} = mat(:) <= 0; %#ok<AGROW>
                    else
                        cons{end + 1, 1} = mat(:) >= 0; %#ok<AGROW>
                    end
                elseif relation == "<="
                    cons{end + 1, 1} = mat <= zero; %#ok<AGROW>
                else
                    cons{end + 1, 1} = mat >= zero; %#ok<AGROW>
                end
            end
        end
    end
end
