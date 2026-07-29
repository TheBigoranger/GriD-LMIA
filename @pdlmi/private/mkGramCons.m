function cons = mkGramCons(expr, relation, targetDeg, specs, comparisonMode, validationMode, bandWidth)
    %MKGRAMCONS Assemble a specified Bernstein-Gram certificate per cell/row.
    %
    %   Each physical cell and active rate row receives an independent
    %   certificate. Entry-wise mode additionally creates an independent
    %   scalar certificate for each MATLAB column-major matrix entry.
    if nargin < 7
        bandWidth = [];
    end

    vals = expr.elevVals(targetDeg - expr.Degree, validationMode);
    validateAssemblyValues(expr, vals, targetDeg, validationMode);
    cells = expr.cells();
    nPar = numel(expr.GridInfo.Vectors);
    certificatePlan = mkGramCertificatePlan( ...
        specs, nPar, bandWidth, targetDeg);

    if comparisonMode == "elementwise"
        certificatesPerRow = prod(expr.MatrixSize);
        gramMatrixSize = 1;
    else
        certificatesPerRow = 1;
        gramMatrixSize = expr.MatrixSize(1);
    end
    localCertificateCount = countLocalCertificates( ...
        vals, cells, certificatesPerRow);
    constraintsPerCertificate = certificatePlan.BlockCount + ...
        certificatePlan.TargetCount;
    cons = cell(localCertificateCount * constraintsPerCertificate, 1);
    nextConstraint = 0;
    planValidated = false(certificatePlan.BlockCount, 1);

    for c = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(c, :));
        for row = 1:size(coeffs, 1)
            % Relation negation changes only the exact matching target.
            target = coeffs(row, :);
            if relation == "<="
                for targetIndex = 1:numel(target)
                    target{targetIndex} = -target{targetIndex};
                end
            end

            if comparisonMode == "elementwise"
                for entry = 1:prod(expr.MatrixSize)
                    scalarTarget = cellfun(@(matrix) matrix(entry), ...
                        target, "UniformOutput", false);
                    appendCertificate(1, scalarTarget);
                end
            else
                appendCertificate(gramMatrixSize, target);
            end
        end
    end

    function appendCertificate(matrixSize, target)
        % Preserve the public order: local cones, then exact coefficient matches.
        [coneConstraints, represented, planValidated] = ...
            mkCert(matrixSize, certificatePlan, ...
            validationMode, planValidated);
        coneCount = numel(coneConstraints);
        if coneCount > 0
            indices = nextConstraint + (1:coneCount);
            cons(indices) = coneConstraints;
            nextConstraint = nextConstraint + coneCount;
        end
        for coefficientIndex = 1:certificatePlan.TargetCount
            nextConstraint = nextConstraint + 1;
            cons{nextConstraint} = ...
                represented{coefficientIndex} == target{coefficientIndex};
        end
    end
end

function count = countLocalCertificates(vals, cells, certificatesPerRow)
    %COUNTLOCALCERTIFICATES Count exact independent local Gram certificates.
    count = 0;
    for cellIndex = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(cellIndex, :));
        count = count + size(coeffs, 1) * certificatesPerRow;
    end
end

function [cons, coeffs, planValidated] = mkCert( ...
        matrixSize, certificatePlan, validationMode, planValidated)
    %MKCERT Allocate fresh Gram variables and realize precomputed maps.
    cons = cell(certificatePlan.BlockCount, 1);
    coeffs = repmat({zeros(matrixSize)}, ...
        1, certificatePlan.TargetCount);
    for block = 1:certificatePlan.BlockCount
        plan = certificatePlan.Blocks{block};
        dimension = matrixSize * plan.BasisCount;
        gram = sdpvar(dimension, dimension, 'symmetric');
        cons{block} = gram >= 0;

        validateInstance = validationMode == "strict" || ...
            ~planValidated(block);
        term = applyGramPlan(gram, plan, validateInstance);
        planValidated(block) = true;
        for coefficient = 1:certificatePlan.TargetCount
            coeffs{coefficient} = coeffs{coefficient} + ...
                term{coefficient};
        end
    end
end
