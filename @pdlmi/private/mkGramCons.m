function cons = mkGramCons(expr, relation, targetDeg, specs, mode, bandWidth)
    %MKGRAMCONS Assemble a specified Bernstein-Gram certificate per cell/row.
    %
    %   Syntax:
    %     cons = mkGramCons(expr, relation, targetDeg, specs, mode)
    %     cons = mkGramCons(expr, relation, targetDeg, specs, mode, bandWidth)
    %
    %   Arguments:
    %     expr      - pdvar residual with local Bernstein coefficients.
    %     relation  - Normalized "<=" or ">=" comparison relation.
    %     targetDeg - Common tensor degree used for exact coefficient matching.
    %     specs     - PSD-block specifications: Gram degree and [alpha; 1-alpha]
    %                 weight exponents in each row.
    %     mode      - "semidefinite" or "elementwise" inequality assembly.
    %     bandWidth - Optional tensor-window side length. Omit for dense blocks.
    %
    %   Output:
    %     cons - Cell column of PSD and exact coefficient-matching constraints.
    %
    %   The result contains one independent matrix certificate per physical
    %   cell/rate row in semidefinite mode. Entry-wise mode instead creates an
    %   independent scalar certificate for each column-major matrix entry.
    if nargin < 6
        bandWidth = [];
    end

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
                    [coneCons, represented] = mkCert( ...
                        1, nPar, specs, bandWidth);
                    cons = [cons; coneCons]; %#ok<AGROW>
                    for k = 1:numel(scalarTarget)
                        cons{end + 1, 1} = represented{k} == scalarTarget{k}; %#ok<AGROW>
                    end
                end
            else
                [coneCons, represented] = mkCert( ...
                    expr.MatrixSize(1), nPar, specs, bandWidth);
                cons = [cons; coneCons]; %#ok<AGROW>
                % Matching is exact; strictness remains encoded in the residual.
                for k = 1:numel(target)
                    cons{end + 1, 1} = represented{k} == target{k}; %#ok<AGROW>
                end
            end
        end
    end
end

function [cons, coeffs] = mkCert(n, nPar, specs, bandWidth)
    %MKCERT Create Gram blocks and sum their weighted Bernstein maps.
    %
    %   Syntax:
    %     [cons, coeffs] = mkCert(n, nPar, specs, bandWidth)
    %
    %   Arguments:
    %     n    - Matrix dimension of each local residual coefficient.
    %     nPar - Number of scheduling-parameter directions.
    %     specs     - Gram-block specifications from mkGramCons.
    %     bandWidth - Empty for dense blocks, or a tensor-window side length.
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
        weight = specs{k, 2};
        alphaPower = reshape(weight(1, :), 1, nPar);
        oneMinusAlphaPower = reshape(weight(2, :), 1, nPar);
        if isempty(bandWidth)
            dim = n * prod(gramDeg + 1);
            gram = sdpvar(dim, dim, 'symmetric');
            cons{end + 1, 1} = gram >= 0; %#ok<AGROW>
            term = bernGramCoeffs(gram, gramDeg, ...
                alphaPower, oneMinusAlphaPower);
            coeffs = addTerm(coeffs, term);
        else
            % Tensor-coordinate windows avoid any dependence on the flattened
            % helper.combRows position of neighboring basis labels.
            winSize = min(bandWidth, gramDeg + 1);
            localLabels = labelRows(winSize - 1);
            starts = labelRows(gramDeg - winSize + 1);
            for w = 1:size(starts, 1)
                basisLabels = localLabels + starts(w, :);
                dim = n * size(basisLabels, 1);
                gram = sdpvar(dim, dim, 'symmetric');
                cons{end + 1, 1} = gram >= 0; %#ok<AGROW>
                term = bernGramCoeffs(gram, gramDeg, ...
                    alphaPower, oneMinusAlphaPower, basisLabels);
                coeffs = addTerm(coeffs, term);
            end
        end
    end
end

function rows = labelRows(maxLabel)
    %LABELROWS Enumerate one tensor box of nonnegative labels.
    ranges = arrayfun(@(d) 0:d, maxLabel, "UniformOutput", false);
    rows = helper.combRows(ranges);
end

function coeffs = addTerm(coeffs, term)
    %ADDTERM Accumulate one dense or windowed Gram contribution.
    if isempty(coeffs)
        coeffs = term;
        return
    end
    for j = 1:numel(coeffs)
        coeffs{j} = coeffs{j} + term{j};
    end
end
