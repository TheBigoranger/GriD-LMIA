function vals = zipRateRows(obj, lhsVals, rhsVals, fcn, grid, errId)
    %ZIPRATEROWS Combine nested coefficient trees with one-row broadcasting.
    %
    %   Syntax:
    %     vals = obj.zipRateRows(lhsVals, rhsVals, fcn, grid, errId)
    %
    %   Arguments:
    %     lhsVals - Nested coefficient tree for the left operand.
    %     rhsVals - Nested coefficient tree for the right operand.
    %     fcn     - Binary function applied to aligned coefficient payloads.
    %     grid    - Common tensor grid used to enumerate physical cells.
    %     errId   - Error identifier owned by the public caller.
    %
    %   Output:
    %     vals - Nested coefficient tree containing the zipped result.
    %
    %   Example:
    %     vals = obj.zipRateRows(lhsVals, rhsVals, @(a, b) a - b, ...
    %         obj.GridInfo.Vectors, "pdvar:IncompatibleOperands");
    %
    %   This helper keeps rate-row broadcasting local to each physical cell.
    %   It delegates row-count checks to joinRateRows so binary algebra and
    %   derivative-aware assignment use the same ordinary-versus-rate rule.

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) obj.joinRateRows( ...
        {helper.cellGet(lhsVals, subs), helper.cellGet(rhsVals, subs)}, ...
        @(parts) fcn(parts{1}, parts{2}), errId));
end
