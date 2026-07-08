function rb = pickRb(errId, varargin)
    %PICKRB Pick the RateBounds carried by a dpvar operation.

    rb = [];
    needRb = false;
    for k = 1:numel(varargin)
        val = varargin{k};
        needRb = needRb || hasRateRows(val);
        if ~isa(val, "dpvar") || isempty(val.RateBounds)
            % Operands without metadata inherit the nonempty bounds selected
            % from their peer; they are not a mismatch by themselves.
            continue
        end
        if isempty(rb)
            rb = val.RateBounds;
        elseif ~isequal(rb, val.RateBounds)
            error(errId, "dpvar operands must have matching RateBounds.");
        end
    end

    if needRb && isempty(rb)
        error(errId, "Rate-vertex dpvar expressions require RateBounds.");
    end
end
