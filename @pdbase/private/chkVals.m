function [hasRate, rowKind] = chkVals(vals, nCell, nCoeff, sz, nPar, ...
        nRateRows, forceRateRows, mode)
    %CHKVALS Validate normalized cell-local Bernstein storage.
    %
    %   Syntax:
    %     [hasRate, rowKind] = chkVals(vals, nCell, nCoeff, sz, ...
    %         nPar, nRateRows, forceRateRows, mode)
    %
    %   Arguments:
    %     vals    - Nested LocalValues cell array, one level per parameter.
    %     nCell   - Number of physical cells in each parameter direction.
    %     nCoeff  - Number of Bernstein coefficients in each physical cell.
    %     sz      - Required [rows, columns] size of each coefficient matrix.
    %     nPar    - Number of scheduling parameters.
    %     nRateRows - Number of distinct vertices implied by RateBounds.
    %     forceRateRows - True when a one-row table is explicitly rate data.
    %     mode    - "fast" or "strict" structural validation.
    %
    %   Output:
    %     hasRate - True when vals contains rate-vertex or rate-affine data.
    %     rowKind - Uniform "ordinary" or "rate" leaf classification.
    %
    %   Malformed nesting, coefficient counts, payloads, or sizes raise a
    %   pdbase validation error.

    helper.chk(vals, "pdbase:InvalidLocalValues", ...
        "LocalValues", ...
        "cell", "Numel", nCell(1));

    if nargin < 8
        mode = "strict";
    end
    hasRate = false;
    rowKind = "";
    if mode == "fast"
        % Constructor-generated trees are structurally uniform. Sampling index
        % one at each nesting level reaches the first physical cell, whose
        % complete coefficient table (including every rate row) is still checked.
        indices = 1;
    else
        indices = 1:nCell(1);
    end
    for k = indices
        if isscalar(nCell)
            coeffs = vals{k};
            [oneRate, oneKind] = chkRow(coeffs, nCoeff, sz, nPar, ...
                nRateRows, forceRateRows);
        else
            % Recurse through one physical-grid dimension at a time.
            [oneRate, oneKind] = chkVals(vals{k}, ...
                nCell(2:end), nCoeff, sz, nPar, nRateRows, ...
                forceRateRows, mode);
        end
        hasRate = oneRate || hasRate;
        if rowKind == ""
            rowKind = oneKind;
        elseif rowKind ~= oneKind
            error("pdbase:InvalidCoefficientRows", ...
                "LocalValues cannot mix ordinary and rate-vertex rows across physical cells.");
        end
    end
end

function [hasRate, rowKind] = chkRow(coeffs, nCoeff, sz, nPar, ...
        nRateRows, forceRateRows)
    %CHKROW Validate one physical-cell coefficient table and classify its rows.
    % A leaf is flat or has one row per distinct parameter-rate-box vertex.

    helper.chk(coeffs, "pdbase:InvalidCoefficientCell", ...
        "physical coefficient row", ...
        "cell");

    isRateTable = nRateRows > 0 && size(coeffs, 1) == nRateRows && ...
        size(coeffs, 2) == nCoeff && (nRateRows > 1 || forceRateRows);
    if ~isRateTable
        helper.chk(coeffs, "pdbase:InvalidCoefficientCell", ...
            "ordinary physical coefficient row", ...
            "Size", [1, nCoeff]);
    end
    if forceRateRows && ~isRateTable
        error("pdbase:InvalidCoefficientCell", ...
            "Rate-row coefficient tables must match the distinct RateBounds vertices.");
    end

    hasRate = isRateTable;
    if isRateTable
        rowKind = "rate";
    else
        rowKind = "ordinary";
    end
    for c = 1:nCoeff
        for row = 1:size(coeffs, 1)
            val = coeffs{row, c};
            if isstruct(val) && isfield(val, "Constant") && isfield(val, "Rate")
                helper.chk(val, "pdbase:InvalidCoefficientPayload", ...
                    "rate-affine coefficient payload", ...
                    "struct", "scalar");
                helper.chk(val.Rate, "pdbase:InvalidCoefficientPayload", ...
                    "rate-affine coefficient Rate field", ...
                    "cell", "Numel", nPar);
                % Rate vertices stay outside ordinary payloads; this only
                % checks that every affine term has the same matrix shape.
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
end

function chkMat(val, sz)
    %CHKMAT Validate a numeric or symbolic coefficient matrix.
    if isa(val, "sdpvar")
        if ~ismatrix(val) || ~isequal(size(val), sz) || ~isreal(val)
            error("pdbase:InvalidCoefficientPayload", ...
                "Each symbolic local coefficient payload must be a real 2-D sdpvar matrix matching matrixSize.");
        end
        return
    end

    helper.chk(val, "pdbase:InvalidCoefficientPayload", ...
        "ordinary local coefficient payload", ...
        "numeric", "real", "finite", "Size", sz);
end
