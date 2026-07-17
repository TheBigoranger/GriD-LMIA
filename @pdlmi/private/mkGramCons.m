function cons = mkGramCons(expr, relation, targetDeg, specs, mode)
    %MKGRAMCONS Assemble a specified Bernstein-Gram certificate per cell/row.
    %
    %   Syntax:
    %     cons = mkGramCons(expr, relation, targetDeg, specs, mode)
    %
    %   Arguments:
    %     expr      - pdvar residual with local Bernstein coefficients.
    %     relation  - Normalized "<=" or ">=" comparison relation.
    %     targetDeg - Common tensor degree used for exact coefficient matching.
    %     specs     - PSD-block specifications: Gram degree and [alpha; 1-alpha]
    %                 weight exponents in each row.
    %     mode      - "semidefinite" or "elementwise" inequality assembly.
    %
    %   Output:
    %     cons - Cell column of PSD and exact coefficient-matching constraints.
    %
    %   The result contains one independent matrix certificate per physical
    %   cell/rate row in semidefinite mode. Entry-wise mode instead creates an
    %   independent scalar certificate for each column-major matrix entry.

    vals = expr.elevVals(targetDeg - expr.Degree);
    cells = expr.cells();
    nPar = numel(expr.GridInfo.Vectors);
    cons = {};

    for c = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(c, :));
        for row = 1:size(coeffs, 1)
            % Certificates are independent across cells and active rate rows.
            target = coeffs(row, :);
            for k = 1:numel(target)
                mat = target{k};
                if relation == "<="
                    target{k} = -mat;
                end
            end

            if mode == "elementwise"
                for entry = 1:prod(expr.MatrixSize)
                    % Scalar certificates remain independent across entries;
                    % MATLAB linear indexing preserves column-major entry order.
                    scalarTarget = cellfun(@(mat) mat(entry), target, ...
                        "UniformOutput", false);
                    [psdCons, represented] = mkCert(1, nPar, specs);
                    cons = [cons; psdCons]; %#ok<AGROW>
                    for k = 1:numel(scalarTarget)
                        cons{end + 1, 1} = represented{k} == scalarTarget{k}; %#ok<AGROW>
                    end
                end
            else
                [psdCons, represented] = mkCert(expr.MatrixSize(1), nPar, specs);
                cons = [cons; psdCons]; %#ok<AGROW>
                % Matching is exact; strictness remains encoded in the residual.
                for k = 1:numel(target)
                    cons{end + 1, 1} = represented{k} == target{k}; %#ok<AGROW>
                end
            end
        end
    end
end

function [cons, coeffs] = mkCert(n, nPar, specs)
    %MKCERT Create dense Gram blocks and sum their weighted Bernstein maps.
    %
    %   Syntax:
    %     [cons, coeffs] = mkCert(n, nPar, specs)
    %
    %   Arguments:
    %     n    - Matrix dimension of each local residual coefficient.
    %     nPar - Number of scheduling-parameter directions.
    %     specs - PSD-block specifications from mkGramCons.
    %
    %   Output:
    %     cons   - Cell column of PSD constraints for the active Gram blocks.
    %     coeffs - Flat Bernstein coefficient cell for their weighted sum.
    %
    %   Negative nominal Gram degrees denote omitted order-zero multiplier blocks.
    cons = {};
    coeffs = {};
    for k = 1:size(specs, 1)
        gramDeg = reshape(specs{k, 1}, 1, []);
        if any(gramDeg < 0)
            % At order zero, multiplier blocks have an empty nominal basis.
            continue
        end
        dim = n * prod(gramDeg + 1);
        gram = sdpvar(dim, dim, 'symmetric');
        cons{end + 1, 1} = gram >= 0; %#ok<AGROW>
        weight = specs{k, 2};
        term = bernGramCoeffs(gram, gramDeg, ...
            reshape(weight(1, :), 1, nPar), ...
            reshape(weight(2, :), 1, nPar));
        if isempty(coeffs)
            coeffs = term;
        else
            for j = 1:numel(coeffs)
                coeffs{j} = coeffs{j} + term{j}; %#ok<AGROW>
            end
        end
    end
end
