function cons = mkCoeffCons(expr, relation, usePolya, pDeg, comparisonMode, validationMode)
    %MKCOEFFCONS Assemble direct or elevated coefficient constraints.
    %
    %   Syntax:
    %     cons = mkCoeffCons(expr, relation, usePolya, pDeg, mode)
    %
    %   Arguments:
    %     expr     - pdvar residual with local Bernstein coefficients.
    %     relation - Normalized "<=", ">=", or "==" relation.
    %     usePolya - True to elevate coefficients before assembly.
    %     pDeg     - Per-parameter Pólya elevation increment.
    %     comparisonMode - "semidefinite", "elementwise", or "equality".
    %     validationMode - "fast" for representative generated-data checking,
    %                      or "strict" for a complete generated-data check.
    %
    %   Output:
    %     cons - Cell column of YALMIP coefficient constraints.
    %
    %   Each physical cell and active rate row produces one constraint per
    %   local coefficient. Pólya selection changes only the coefficient degree
    %   through exact elevation. Equality vectorizes each coefficient and omits
    %   a constraint only when numeric zero is proven.

    if usePolya
        % The mode belongs only to this certificate build; it is not stored
        % on expr or inherited by later algebra operations.
        vals = expr.elevVals(pDeg, validationMode);
    else
        vals = expr.LocalValues;
    end
    validateAssemblyValues(expr, vals, expr.Degree + usePolya * pDeg, ...
        validationMode);

    if isa(expr, "pdmat")
        cons = {numericCertificate(expr, vals, relation, comparisonMode)};
        return
    end

    cells = expr.cells();
    firstCoeffs = helper.cellGet(vals, cells(1, :));
    cons = cell(size(cells, 1) * numel(firstCoeffs), 1);
    nCons = 0;
    zero = zeros(expr.MatrixSize);
    for c = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(c, :));
        for row = 1:size(coeffs, 1)
            for k = 1:size(coeffs, 2)
                mat = coeffs{row, k};
                % Each row is a rate vertex when rhodiff produced rate rows;
                % ordinary expressions simply have one row.
                if comparisonMode == "equality"
                    % Proven numeric-zero identities need no YALMIP constraint.
                    if helper.isZero(mat, "num")
                        continue
                    end
                    nCons = nCons + 1;
                    cons{nCons} = mat(:) == 0;
                elseif comparisonMode == "elementwise"
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

function tf = numericCertificate(expr, vals, relation, mode)
    %NUMERICCERTIFICATE Test every known Bernstein coefficient at tolerance.
    % A false result means only that this sufficient coefficient certificate
    % failed; it says nothing conclusive about the continuous-domain matrix.

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
                    % Symmetrization prevents harmless numerical skew from
                    % changing the eigenvalue certificate at the tolerance.
                    herm = (mat + mat') / 2;
                    eigVals = eig(herm);
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
