function coeffs = joinRows(leaves, fcn, errId)
    %JOINROWS Combine ordinary rows with rate-vertex coefficient tables.
    %
    %   Syntax:
    %     coeffs = joinRows(leaves, fcn, errId)
    %
    %   Arguments:
    %     leaves - Coefficient tables to align by row and column.
    %     fcn    - Assembly function receiving one value from each leaf.
    %     errId  - Identifier for incompatible row or column counts.
    %
    %   Output:
    %     coeffs - Combined table at the active rate-row count.
    %
    %   Example (via rate-affine algebra):
    %     P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    %     C = rhodiff(P) + P;
    %
    %   LEAVES are cell tables with a common coefficient-column count. A
    %   one-row leaf is broadcast across the largest rate-vertex row count;
    %   any other mismatch is rejected because it would invent vertex data.
    %   FCN receives one coefficient from each input for every output row.

    nCoeff = [];
    nRows = 1;
    for k = 1:numel(leaves)
        if isempty(nCoeff)
            nCoeff = size(leaves{k}, 2);
        elseif size(leaves{k}, 2) ~= nCoeff
            error(errId, ...
                "Coefficient rows must have matching column counts.");
        end
        nRows = max(nRows, size(leaves{k}, 1));
    end

    for k = 1:numel(leaves)
        if size(leaves{k}, 1) ~= nRows && size(leaves{k}, 1) ~= 1
            error(errId, ...
                "Coefficient rows cannot be broadcast to the rate vertices.");
        end
    end

    coeffs = cell(nRows, nCoeff);
    for row = 1:nRows
        for c = 1:nCoeff
            parts = cell(1, numel(leaves));
            for k = 1:numel(leaves)
                one = leaves{k};
                parts{k} = one{min(row, size(one, 1)), c};
            end
            coeffs{row, c} = fcn(parts);
        end
    end
end
