function init = mkCtorState(grid, sz, deg, vals, hasDec, rb, summary, ...
        isCont, validationMode, numRateRows)
    %MKCTORSTATE Package prepared coefficient data for the pdvar constructor.
    %
    %   Syntax:
    %     init = mkCtorState(grid, sz, deg, vals, hasDec, rb, ...
    %         summary, isCont, validationMode, numRateRows)
    %
    %   Arguments:
    %     grid, sz, deg, vals - Grid, matrix size, degree, and LocalValues.
    %     hasDec              - Decision-dependence flag.
    %     rb, summary         - RateBounds and source label.
    %     isCont              - Optional continuity flag; default true.
    %     validationMode      - Optional "fast" or "strict" validation.
    %     numRateRows         - Zero or the number of explicit rate rows.
    %
    %   Output:
    %     init - Validated-state struct accepted only by pdvar internals.
    %
    %   Example (via public algebra):
    %     P = pdvar(1, {[0 1]});
    %     Q = -P;  % Unary algebra packages data through mkCtorState.


    if nargin < 10 || isempty(numRateRows)
        numRateRows = 0;
    end
    if numRateRows ~= 0
        % Active derivative vertices remain deliberately cell-local even when
        % a particular coefficient realization happens to match at a face.
        isCont = false;
    elseif nargin < 8 || isempty(isCont)
        % Recompute globally unless the caller supplies an exact preservation
        % proof; an operand-level continuity flag cannot detect cancellation.
        nCell = cellfun(@numel, grid) - 1;
        isCont = helper.chkCont(vals, nCell, deg);
    end
    if nargin < 9
        validationMode = "fast";
    end

    init = struct( ...
        "PdvarInternal", true, ...
        "Grid", {grid}, ...
        "MatrixSize", sz, ...
        "Degree", deg, ...
        "LocalValues", {vals}, ...
        "IsContinuous", isCont, ...
        "ContainsDecision", hasDec, ...
        "NumRateRows", numRateRows, ...
        "RateBounds", rb, ...
        "SourceSummary", summary, ...
        "ValidationMode", validationMode);
end
