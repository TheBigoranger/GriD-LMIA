function hasRate = chkVals(vals, nCell, nCoeff, sz, nPar, layout, srcDeg)
    %CHKVALS Validate nested cell-local Bernstein payloads.
    if nargin < 6 || strlength(string(layout)) == 0
        layout = "flat";
    else
        layout = string(layout);
    end
    if nargin < 7 || isempty(srcDeg)
        srcDeg = [];
    end

    helper.chk(vals, "dpbase:InvalidLocalValues", ...
        "LocalValues must match the physical nested-cell grid shape.", ...
        "cell", "Numel", nCell(1));

    hasRate = false;
    for k = 1:nCell(1)
        if isscalar(nCell)
            coeffs = vals{k};
            if layout == "derivativeRows"
                helper.chk(coeffs, "dpbase:InvalidCoefficientCell", ...
                    "Derivative LocalValues entries must store one coefficient row per parameter.", ...
                    "cell", "Numel", nPar);
                for r = 1:nPar
                    nRow = derivCount(srcDeg, nPar);
                    hasRate = chkCoeffRow(coeffs{r}, nRow, sz, nPar) || hasRate;
                end
            else
                hasRate = chkCoeffRow(coeffs, nCoeff, sz, nPar) || hasRate;
            end
        else
            % Preserve the nested physical-cell shape while walking down one
            % parameter dimension at a time.
            hasRate = internal.chkVals(vals{k}, nCell(2:end), nCoeff, sz, nPar, ...
                layout, srcDeg) || hasRate;
        end
    end
end

function n = derivCount(srcDeg, nPar)
    if isempty(srcDeg) || srcDeg == 0
        n = 1;
    else
        n = srcDeg * (srcDeg + 1) ^ (nPar - 1);
    end
end

function hasRate = chkCoeffRow(coeffs, nCoeff, sz, nPar)
    helper.chk(coeffs, "dpbase:InvalidCoefficientCell", ...
        "Each physical coefficient row must be a flat coefficient cell with the expected count.", ...
        "cell", "Numel", nCoeff);

    hasRate = false;
    for c = 1:nCoeff
        val = coeffs{c};
        if isstruct(val) && isfield(val, "Constant") && isfield(val, "Rate")
            helper.chk(val, "dpbase:InvalidCoefficientPayload", ...
                "Rate-affine coefficient payload must be a scalar struct.", ...
                "struct", "scalar");
            helper.chk(val.Rate, "dpbase:InvalidCoefficientPayload", ...
                "Rate-affine coefficient payload Rate field must be a cell array with one entry per parameter.", ...
                "cell", "Numel", nPar);
            % Rate vertices stay outside LocalValues; this only checks
            % that every affine term has the same finite matrix shape.
            chkMat(val.Constant, sz);
            for r = 1:numel(val.Rate)
                chkMat(val.Rate{r}, sz);
            end
            hasRate = true;
        else
            chkMat(val, sz);
        end
    end
end

function chkMat(val, sz)
    % dpbase validates storage shape only; subclasses own symbolic algebra.
    if isa(val, "sdpvar")
        if ~ismatrix(val) || ~isequal(size(val), sz) || ~isreal(val)
            error("dpbase:InvalidCoefficientPayload", ...
                "Each symbolic local coefficient payload must be a real 2-D sdpvar matrix matching matrixSize.");
        end
        return
    end

    helper.chk(val, "dpbase:InvalidCoefficientPayload", ...
        "Each ordinary local coefficient payload must be a finite real numeric or real 2-D sdpvar matrix matching matrixSize.", ...
        "numeric", "real", "finite", "Size", sz);
end
