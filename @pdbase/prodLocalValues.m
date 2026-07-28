function vals = prodLocalValues(obj, lhsVals, lhsDeg, rhsVals, rhsDeg, ...
        grid, errId, plan, validationMode)
    %PRODLOCALVALUES Apply one product plan across all cells and rate rows.

    if nargin < 9 || isempty(validationMode)
        validationMode = "fast";
    end
    if nargin < 8 || isempty(plan)
        plan = obj.productPlan(lhsDeg, rhsDeg);
    end
    nCell = cellfun(@numel, grid) - 1;
    firstCell = true;
    vals = helper.mkNest(nCell, @productAt);

    function coeffs = productAt(subs)
        % mkNest visits the all-ones physical cell first. Fast mode validates
        % its complete leaf once; strict mode repeats the same check per cell.
        validateInstance = validationMode == "strict" || firstCell;
        coeffs = obj.prodRateRows( ...
            helper.cellGet(lhsVals, subs), lhsDeg, ...
            helper.cellGet(rhsVals, subs), rhsDeg, errId, ...
            plan, validateInstance);
        firstCell = false;
    end
end
