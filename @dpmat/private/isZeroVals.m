function tf = isZeroVals(vals)
    %ISZEROVALS True when every stored numeric coefficient is zero.

    if iscell(vals)
        tf = true;
        for k = 1:numel(vals)
            if ~isZeroVals(vals{k})
                tf = false;
                return
            end
        end
        return
    end

    tf = isnumeric(vals) && all(vals(:) == 0);
end
