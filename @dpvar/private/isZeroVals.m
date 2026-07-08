function tf = isZeroVals(vals)
    %ISZEROVALS True when every numeric/YALMIP coefficient is zero.

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

    if isstruct(vals)
        tf = isZeroVals(vals.Constant) && isZeroVals(vals.Rate);
        return
    end

    if isa(vals, "sdpvar")
        base = full(getbase(vals));
        tf = all(base(:) == 0);
        return
    end

    tf = isnumeric(vals) && all(vals(:) == 0);
end
