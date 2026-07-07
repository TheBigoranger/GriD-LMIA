function tf = isDeriv(val)
    %ISDERIV True for derivative-row dpvar expressions.

    tf = isa(val, "dpvar") && strcmp(string(val.SourceSummary), "derivative");
end
