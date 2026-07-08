function coeffs = joinRows(leaves, fcn, errId)
    %JOINROWS Combine ordinary rows with rate-vertex coefficient tables.

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
