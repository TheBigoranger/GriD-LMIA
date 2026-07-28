function [hasRate, rowKind] = chkVals(vals, nCell, nCoeff, sz, nPar, mode)
    %CHKVALS Validate normalized cell-local Bernstein storage.
    %
    %   Syntax:
    %     hasRate = chkVals(vals, nCell, nCoeff, sz, nPar)
    %
    %   Arguments:
    %     vals    - Nested LocalValues cell array, one level per parameter.
    %     nCell   - Number of physical cells in each parameter direction.
    %     nCoeff  - Number of Bernstein coefficients in each physical cell.
    %     sz      - Required [rows, columns] size of each coefficient matrix.
    %     nPar    - Number of scheduling parameters.
    %
    %   Output:
    %     hasRate - True when vals contains rate-vertex or rate-affine data.
    %
    %   Example:
    %     vals = {{1, 2}}; % One cell with two scalar coefficients.
    %     hasRate = chkVals(vals, 1, 2, [1 1], 1);
    %
    %   Malformed nesting, coefficient counts, payloads, or sizes raise a
    %   pdbase validation error.

    helper.chk(vals, "pdbase:InvalidLocalValues", ...
        "LocalValues must match the physical nested-cell grid shape.", ...
        "cell", "Numel", nCell(1));

    if nargin < 6
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
            [oneRate, oneKind] = chkCoeffRow(coeffs, nCoeff, sz, nPar);
        else
            % Recurse through one physical-grid dimension at a time.
            [oneRate, oneKind] = chkVals(vals{k}, ...
                nCell(2:end), nCoeff, sz, nPar, mode);
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

function [hasRate, rowKind] = chkCoeffRow(coeffs, nCoeff, sz, nPar)
    %CHKCOEFFROW Validate one physical-cell leaf and classify rate storage.
    % A leaf is flat or has one row per corner of the parameter-rate box.

    helper.chk(coeffs, "pdbase:InvalidCoefficientCell", ...
        "Each physical coefficient row must be a flat coefficient cell or a rate-vertex coefficient table.", ...
        "cell");

    isRateTable = size(coeffs, 1) == 2 ^ nPar && ...
        size(coeffs, 2) == nCoeff;
    if ~isRateTable
        helper.chk(coeffs, "pdbase:InvalidCoefficientCell", ...
            "Each ordinary physical coefficient row must have the expected coefficient count.", ...
            "Size", [1, nCoeff]);
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
                    "Rate-affine coefficient payload must be a scalar struct.", ...
                    "struct", "scalar");
                helper.chk(val.Rate, "pdbase:InvalidCoefficientPayload", ...
                    "Rate-affine coefficient payload Rate field must be a cell array with one entry per parameter.", ...
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
        "Each ordinary local coefficient payload must be a finite real numeric or real 2-D sdpvar matrix matching matrixSize.", ...
        "numeric", "real", "finite", "Size", sz);
end
