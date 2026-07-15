function vals = mkNest(nCell, mkLeaf, prefix)
    %MKNEST Build nested physical-cell storage with a caller-defined leaf.
    %
    %   Syntax:
    %     vals = helper.mkNest(nCell, mkLeaf)
    %
    %   Arguments:
    %     nCell - Positive cell count per parameter direction.
    %     mkLeaf - Function receiving one physical-cell subscript row.
    %     prefix - Internal recursion prefix; callers normally omit it.
    %
    %   Output:
    %     vals - Nested tree addressed as vals{i1}{i2}...{i_ell}.
    %
    %   Example:
    %     vals = helper.mkNest([2 1], @(subs) {sum(subs)});

    if nargin < 3
        prefix = [];
    end

    vals = cell(1, nCell(1));
    for k = 1:nCell(1)
        subs = zeros(1, numel(prefix) + 1);
        subs(1:numel(prefix)) = prefix;
        subs(end) = k;
        if isscalar(nCell)
            vals{k} = mkLeaf(subs);
        else
            % Nested cells preserve LocalValues{i1}{i2}... physical access.
            vals{k} = helper.mkNest(nCell(2:end), mkLeaf, subs);
        end
    end
end
