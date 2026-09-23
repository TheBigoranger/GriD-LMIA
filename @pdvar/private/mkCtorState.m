function init = mkCtorState(grid, sz, deg, vals, hasDec, rb, summary, ...
        continuity, validationMode, numRateRows)
    %MKCTORSTATE Package prepared coefficient data for the pdvar constructor.
    %
    %   Syntax:
    %     init = mkCtorState(grid, sz, deg, vals, hasDec, rb, ...
    %         summary, continuity, validationMode, numRateRows)
    %
    %   Arguments:
    %     grid, sz, deg, vals - Grid, matrix size, degree, and LocalValues.
    %     hasDec              - Decision-dependence flag.
    %     rb, summary         - RateBounds and source label.
    %     continuity          - Optional proven direction-wise lower bound.
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
    if nargin < 8 || isempty(continuity)
        nCell = cellfun(@numel, grid) - 1;
        [~, continuity] = helper.chkCont(vals, nCell, deg, grid);
    elseif any(continuity < 0)
        continuity = recoverC0(vals, grid, deg, continuity);
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
        "Continuity", continuity, ...
        "ContainsDecision", hasDec, ...
        "NumRateRows", numRateRows, ...
        "RateBounds", rb, ...
        "SourceSummary", summary, ...
        "ValidationMode", validationMode);
end

function continuity = recoverC0(vals, grid, degree, continuity)
    %RECOVERC0 Recover only lost C0 evidence after a propagated -1 bound.
    nCell = cellfun(@numel, grid) - 1;
    [~, recovered] = helper.chkCont(vals, nCell, degree, grid, ...
        zeros(1, numel(grid)));
    lost = continuity < 0;
    continuity(lost) = recovered(lost);
end
