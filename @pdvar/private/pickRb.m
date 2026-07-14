function rb = pickRb(errId, varargin)
    %PICKRB Pick the RateBounds carried by a pdvar operation.
    %
    %   Syntax:
    %     rb = pickRb(errId, operand1, operand2, ...)
    %
    %   Example (via public algebra):
    %     P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    %     C = P + 1;
    %
    %   Empty metadata on numeric or ordinary operands is allowed to inherit
    %   the nonempty bounds of a rate-dependent peer. Distinct nonempty bounds
    %   are a hard mismatch, and rate-row data without bounds is invalid.

    rb = [];
    needRb = false;
    for k = 1:numel(varargin)
        val = varargin{k};
        needRb = needRb || hasRateRows(val);
        if ~isa(val, "pdvar") || isempty(val.RateBounds)
            % Operands without metadata inherit the nonempty bounds selected
            % from their peer; they are not a mismatch by themselves.
            continue
        end
        if isempty(rb)
            rb = val.RateBounds;
        elseif ~isequal(rb, val.RateBounds)
            error(errId, "pdvar operands must have matching RateBounds.");
        end
    end

    if needRb && isempty(rb)
        error(errId, "Rate-vertex pdvar expressions require RateBounds.");
    end
end
