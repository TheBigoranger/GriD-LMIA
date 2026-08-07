function coeffs = joinRateRows(~, leaves, fcn, errId)
    %JOINRATEROWS Assemble aligned coefficient tables from several operands.
    %
    %   Syntax:
    %     coeffs = obj.joinRateRows(leaves, fcn, errId)
    %
    %   Arguments:
    %     leaves - Cell array of flat coefficient tables from aligned operands.
    %              Each table has either one ordinary row or the active
    %              derivative-rate vertex rows.
    %     fcn    - Function handle applied to one aligned coefficient tuple.
    %     errId  - Error identifier owned by the public caller.
    %
    %   Output:
    %     coeffs - Flat coefficient table with the active row count and the
    %              shared coefficient-column count.
    %
    %   Example:
    %     coeffs = obj.joinRateRows({lhsLeaf, rhsLeaf}, ...
    %         @(parts) parts{1} + parts{2}, "pdvar:IncompatibleOperands");
    %
    %   Ordinary one-row leaves broadcast to the active rate-row count. Any
    %   other row or coefficient-column mismatch is rejected.

    nCoeff = [];
    nRows = 1;
    for k = 1:numel(leaves)
        leaf = leaves{k};
        if isempty(nCoeff)
            nCoeff = size(leaf, 2);
        elseif size(leaf, 2) ~= nCoeff
            error(errId, ...
                "Coefficient rows must have matching column counts.");
        end
        nRows = max(nRows, size(leaf, 1));
    end

    for k = 1:numel(leaves)
        if size(leaves{k}, 1) ~= 1 && size(leaves{k}, 1) ~= nRows
            error(errId, ...
                "Ordinary coefficient rows cannot be broadcast to the active rate vertices.");
        end
    end

    coeffs = cell(nRows, nCoeff);
    for row = 1:nRows
        for c = 1:nCoeff
            parts = cell(1, numel(leaves));
            for k = 1:numel(leaves)
                leaf = leaves{k};
                parts{k} = leaf{min(row, size(leaf, 1)), c};
            end
            coeffs{row, c} = fcn(parts);
        end
    end
end
