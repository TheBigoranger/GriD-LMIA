function coeffs = cellGet(vals, subs)
    %CELLGET Read nested physical-cell storage by subscript row.
    %
    %   Syntax:
    %     coeffs = helper.cellGet(vals, subs)
    %
    %   Arguments:
    %     vals - Nested LocalValues tree.
    %     subs - One physical-cell index per tree level.
    %
    %   Output:
    %     coeffs - Selected flat coefficient leaf or rate-row table.

    coeffs = vals;
    for k = 1:numel(subs)
        coeffs = coeffs{subs(k)};
    end
end
