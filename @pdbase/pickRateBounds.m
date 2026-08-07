function rb = pickRateBounds(obj, errId, varargin)
    %PICKRATEBOUNDS Reconcile rate metadata for one gridded operation.
    %
    %   Syntax:
    %     rb = obj.pickRateBounds(errId, other1, other2, ...)
    %
    %   Arguments:
    %     errId - Error identifier owned by the public operation.
    %     other - Optional peer operands participating in the operation.
    %
    %   Output:
    %     rb - Empty when no operand needs rate bounds, or the unique
    %          nonempty RateBounds shared by all rate-aware operands.
    %
    %   Example:
    %     rb = obj.pickRateBounds("pdvar:IncompatibleOperands", rhs);
    %
    %   Empty metadata inherits a peer's bounds. Distinct nonempty bounds are
    %   rejected, and explicit rate-row data always requires selected bounds.

    rb = [];
    needRb = false;
    vals = [{obj}, varargin];
    for k = 1:numel(vals)
        val = vals{k};
        if ~isa(val, "pdbase")
            continue
        end
        needRb = needRb || val.NumRateRows ~= 0;
        if isempty(val.RateBounds)
            continue
        end
        if isempty(rb)
            rb = val.RateBounds;
        elseif ~isequal(rb, val.RateBounds)
            error(errId, ...
                "Gridded operands must have matching nonempty RateBounds.");
        end
    end

    if needRb && isempty(rb)
        error(errId, ...
            "Rate-vertex coefficient rows require nonempty RateBounds.");
    end
end
