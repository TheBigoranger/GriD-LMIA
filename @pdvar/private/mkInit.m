function init = mkInit(grid, sz, deg, vals, hasDec, hasRate, rb, summary, isCont)
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


    if nargin < 9
        isCont = true;
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
        "SourceSummary", summary);
end
