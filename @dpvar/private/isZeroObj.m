function tf = isZeroObj(obj)
    %ISZEROOBJ True when a dpvar stores only zero coefficient payloads.

    tf = isa(obj, "dpvar") && isZeroVals(obj.LocalValues);
end
