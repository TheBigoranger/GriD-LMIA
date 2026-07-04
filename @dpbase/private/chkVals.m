function hasRate = chkVals(vals, nCell, nCoeff, sz, nPar)
    %CHKVALS Validate nested cell-local Bernstein payloads.

    helper.chk(vals, "dpbase:InvalidLocalValues", ...
        "LocalValues must match the physical nested-cell grid shape.", ...
        "cell", "Numel", nCell(1));

    hasRate = false;
    for k = 1:nCell(1)
        if isscalar(nCell)
            hasRate = chkCoeffCell(vals{k}, nCoeff, sz, nPar) || hasRate;
        else
            % Preserve the nested physical-cell shape while walking down one
            % parameter dimension at a time.
            hasRate = chkVals(vals{k}, nCell(2:end), nCoeff, sz, nPar) || hasRate;
        end
    end
end

function hasRate = chkCoeffCell(coeffs, nCoeff, sz, nPar)
    helper.chk(coeffs, "dpbase:InvalidCoefficientCell", ...
        "Each physical cell must store a flat coefficient cell with the expected count.", ...
        "cell", "Numel", nCoeff);

    hasRate = false;
    for k = 1:nCoeff
        % hasRate summarizes whether any compact coefficient payload is rate-affine.
        hasRate = chkPayload(coeffs{k}, sz, nPar) || hasRate;
    end
end

function isRate = chkPayload(val, sz, nPar)
    if isstruct(val) && isfield(val, "Constant") && isfield(val, "Rate")
        helper.chk(val, "dpbase:InvalidCoefficientPayload", ...
            "Rate-affine coefficient payload must be a scalar struct.", ...
            "struct", "scalar");
        helper.chk(val.Rate, "dpbase:InvalidCoefficientPayload", ...
            "Rate-affine coefficient payload Rate field must be a cell array with one entry per parameter.", ...
            "cell", "Numel", nPar);
        % Rate-affine payloads are coherent only when every term has the same
        % finite-real matrix shape. Rate vertices remain outside LocalValues.
        chkMat(val.Constant, sz);
        for k = 1:numel(val.Rate)
            chkMat(val.Rate{k}, sz);
        end
        isRate = true;
        return
    end

    chkMat(val, sz);
    isRate = false;
end

function chkMat(val, sz)
    % dpbase is intentionally YALMIP-free at this layer. Symbolic payloads need
    % subclass algebra first, otherwise this parent would silently accept shapes
    % it cannot combine or assemble correctly.
    helper.chk(val, "dpbase:InvalidCoefficientPayload", ...
        "Each ordinary local coefficient payload must be a finite real numeric matrix matching matrixSize.", ...
        "numeric", "real", "finite", "Size", sz);
end
