function cons = coeffCons(expr, relation, usePolya, pDeg, cmpMode, valMode)
    %COEFFCONS Assemble direct or elevated Bernstein coefficient constraints.
    %
    %   Syntax:
    %     cons = coeffCons(expr, relation, usePolya, pDeg, cmpMode, valMode)
    %
    %   Arguments:
    %     expr     - pdvar residual, or coefficient-backed pdmat inequality.
    %     relation - "<=", ">=", or "==".
    %     usePolya - Logical flag selecting componentwise Pólya elevation.
    %     pDeg     - Pólya degree increment when usePolya is true.
    %     cmpMode  - "semidefinite", "elementwise", or "equality".
    %     valMode  - "fast" or "strict" generated-assembly validation mode.
    %
    %   Output:
    %     cons - Cell array of YALMIP constraints for pdvar residuals, or one
    %            logical sufficient certificate for known pdmat inequalities.
    %
    %   Example:
    %     cons = coeffCons(expr, "<=", false, zeros(1, expr.npar()), ...
    %         "semidefinite", "fast");
    %
    %   Direct assembly constrains each local Bernstein coefficient. Pólya
    %   first elevates the residual coefficients by pDeg and then applies the
    %   same coefficient rule. Equality is always entry-wise and skips proven
    %   zero coefficients to avoid empty symbolic equalities.

    if usePolya
        elevated = expr.elevate(pDeg, valMode);
        vals = elevated.LocalValues;
    else
        vals = expr.LocalValues;
    end
    chkAsmVals(expr, vals, expr.Degree + usePolya * pDeg, valMode);
    if isa(expr, "pdmat")
        cons = {numCert(expr, vals, relation, cmpMode)};
        return
    end

    cells = expr.cells();
    first = helper.cellGet(vals, cells(1, :));
    cons = cell(size(cells, 1) * numel(first), 1);
    nCons = 0;
    zero = zeros(expr.MatrixSize);
    for c = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(c, :));
        for row = 1:size(coeffs, 1)
            for k = 1:size(coeffs, 2)
                mat = coeffs{row, k};
                if cmpMode == "equality"
                    if helper.isZero(mat, "num")
                        continue
                    end
                    nCons = nCons + 1;
                    cons{nCons} = mat(:) == 0;
                elseif cmpMode == "elementwise"
                    nCons = nCons + 1;
                    if relation == "<="
                        cons{nCons} = mat(:) <= 0;
                    else
                        cons{nCons} = mat(:) >= 0;
                    end
                elseif relation == "<="
                    nCons = nCons + 1;
                    cons{nCons} = mat <= zero;
                else
                    nCons = nCons + 1;
                    cons{nCons} = mat >= zero;
                end
            end
        end
    end
    cons = cons(1:nCons);
end

function tf = numCert(expr, vals, relation, mode)
    %NUMCERT Test every known coefficient using the established tolerance.
    tol = 1e-10;
    tf = true;
    cells = expr.cells();
    for c = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(c, :));
        for row = 1:size(coeffs, 1)
            for k = 1:size(coeffs, 2)
                mat = coeffs{row, k};
                if mode == "elementwise"
                    if relation == "<="
                        ok = all(mat(:) <= tol);
                    else
                        ok = all(mat(:) >= -tol);
                    end
                else
                    eigVals = eig((mat + mat') / 2);
                    if relation == "<="
                        ok = max(eigVals) <= tol;
                    else
                        ok = min(eigVals) >= -tol;
                    end
                end
                tf = tf && ok;
            end
        end
    end
end
