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
    %
    %   Example:
    %     vals = helper.mkNest([2 1], @(subs) {subs});
    %     coeffs = helper.cellGet(vals, [2 1]);

    coeffs = vals;
    for k = 1:numel(subs)
        coeffs = coeffs{subs(k)};
    end
end
