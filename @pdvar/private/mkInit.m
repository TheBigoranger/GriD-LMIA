function init = mkInit(grid, sz, deg, vals, hasDec, hasRate, rb, summary, isCont, validationMode)
    %MKINIT Package prepared coefficient data for the pdvar constructor.
    %
    %   Syntax:
    %     init = mkInit(grid, sz, deg, vals, hasDec, hasRate, rb, summary, isCont)
    %
    %   Arguments:
    %     grid, sz, deg, vals - Grid, matrix size, degree, and LocalValues.
    %     hasDec, hasRate     - Decision- and rate-dependence flags.
    %     rb, summary         - RateBounds and source label.
    %     isCont              - Optional continuity flag; default true.
    %
    %   Output:
    %     init - Validated-state struct accepted only by pdvar internals.
    %
    %   Example (via public algebra):
    %     P = pdvar(1, {[0 1]});
    %     Q = -P;  % Unary algebra packages data through mkInit.


    firstLeaf = helper.cellGet(vals, ones(1, numel(grid)));
    hasRateRows = hasRate && iscell(firstLeaf) && size(firstLeaf, 1) > 1;
    if hasRateRows
        % Active derivative vertices remain deliberately cell-local even when
        % a particular coefficient realization happens to match at a face.
        isCont = false;
    elseif nargin < 9 || isempty(isCont)
        % Recompute globally unless the caller supplies an exact preservation
        % proof; an operand-level continuity flag cannot detect cancellation.
        nCell = cellfun(@numel, grid) - 1;
        isCont = chkCont(vals, nCell, deg);
    end
    if nargin < 10
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
        "HasRateDependence", hasRate, ...
        "RateBounds", rb, ...
        "SourceSummary", summary, ...
        "ValidationMode", validationMode);
end
