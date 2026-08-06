function [targetDeg, specs] = mkPutinarSpec(expr, order)
    %MKPUTINARSPEC Define the authoritative Putinar parity/mask convention.
    %
    %   One parameter uses the exact Markov-Lukacs parity form shared with
    %   FullBox. Multiple parameters use only the empty and singleton box
    %   generator masks; negative-degree singleton blocks are omitted later by
    %   the shared Gram-plan builder.

    nPar = numel(expr.GridInfo.Vectors);
    if nPar == 1
        [targetDeg, specs] = mkFullBoxSpec(expr, order);
        return
    end

    targetDeg = 2 .* order;
    masks = [zeros(1, nPar); eye(nPar)];
    specs = cell(size(masks, 1), 2);
    for k = 1:size(masks, 1)
        specs{k, 1} = order - masks(k, :);
        specs{k, 2} = [masks(k, :); masks(k, :)];
    end
end
