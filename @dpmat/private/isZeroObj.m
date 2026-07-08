function tf = isZeroObj(obj)
    %ISZEROOBJ True when a dpmat has explicit zero coefficient evidence.

    tf = isa(obj, "dpmat") && obj.SourceSummary ~= "function" && ...
        isZeroVals(obj.LocalValues);
end
