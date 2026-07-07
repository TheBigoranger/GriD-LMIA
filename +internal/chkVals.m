function hasRate = chkVals(vals, nCell, nCoeff, sz, nPar)
    %CHKVALS Validate nested cell-local Bernstein payloads.

    helper.chk(vals, "dpbase:InvalidLocalValues", ...
        "LocalValues must match the physical nested-cell grid shape.", ...
        "cell", "Numel", nCell(1));

    hasRate = false;
    for k = 1:nCell(1)
        if isscalar(nCell)
            coeffs = vals{k};
            helper.chk(coeffs, "dpbase:InvalidCoefficientCell", ...
                "Each physical cell must store a flat coefficient cell with the expected count.", ...
                "cell", "Numel", nCoeff);

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
        else
            % Preserve the nested physical-cell shape while walking down one
            % parameter dimension at a time.
            hasRate = internal.chkVals(vals{k}, nCell(2:end), nCoeff, sz, nPar) || hasRate;
        end
    end
end

function chkMat(val, sz)
    % dpbase is intentionally YALMIP-free at this layer. Symbolic payloads need
    % subclass algebra first, otherwise this parent would silently accept shapes
    % it cannot combine or assemble correctly.
    helper.chk(val, "dpbase:InvalidCoefficientPayload", ...
        "Each ordinary local coefficient payload must be a finite real numeric matrix matching matrixSize.", ...
        "numeric", "real", "finite", "Size", sz);
end
