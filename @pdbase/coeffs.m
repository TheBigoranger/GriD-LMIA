function c = coeffs(obj, cellSubs)
    %COEFFS Return the flat coefficient cell for one physical cell.
    %
    %   Syntax:
    %     c = coeffs(obj, cellSubs)
    %     c = obj.coeffs(cellSubs)
    %
    %   Example:
    %     obj = pdbase({[0 1 2]}, [1 1], 1);
    %     c = obj.coeffs(2);

    nCell = obj.GridInfo.NumNodes - 1;
    if iscell(cellSubs)
        helper.chk(cellSubs, "pdbase:InvalidCellSubs", ...
            "cellSubs must provide one physical-cell index per parameter.", ...
            "cell", "Numel", numel(nCell));
        subs = cellfun(@double, cellSubs);
    else
        subs = double(cellSubs);
    end

    subs = reshape(subs, 1, []);
    helper.chk(subs, "pdbase:InvalidCellSubs", ...
        "cellSubs must be valid positive integer physical-cell subscripts.", ...
        "numeric", "finite", "integer", "positive", "Numel", numel(nCell));
    if any(subs > nCell)
        error("pdbase:InvalidCellSubs", ...
            "cellSubs must be valid positive integer physical-cell subscripts.");
    end

    % Physical cells use nested access: LocalValues{i1}{i2}...{i_ell}.
    % This differs from MATLAB multi-index cell syntax and preserves the
    % storage contract shared by future pdmat/pdvar subclasses.
    c = obj.LocalValues;
    for k = 1:numel(subs)
        c = c{subs(k)};
    end
end
