function out = mkCoeffObj(grid, vals, deg, rb, summary, isCont, sz, ...
        validationMode, numRateRows)
    %MKCOEFFOBJ Rebuild coefficient-backed pdmat data without a user warning.
    %
    %   Syntax:
    %     out = mkCoeffObj(grid, vals, deg)
    %     out = mkCoeffObj(grid, vals, deg, rb, summary, isCont, sz, ...
    %         validationMode, numRateRows)
    %
    %   Arguments:
    %     grid           - Physical parameter grid vectors.
    %     vals           - Nested local coefficient tree.
    %     deg            - 1-by-ell Bernstein degree.
    %     rb             - Optional RateBounds metadata.
    %     summary        - Optional SourceSummary value.
    %     isCont         - Optional known continuity classification.
    %     sz             - Optional matrix payload size.
    %     validationMode - Optional "fast" or "strict" constructor validation.
    %     numRateRows    - Zero or the number of explicit rate rows.
    %
    %   Output:
    %     out - Coefficient-backed pdmat with no FunctionHandle.
    %
    %   Example:
    %     out = mkCoeffObj(grid, vals, deg, [], ...
    %         "coefficient-backed", true, [1 1]);
    %
    %   A caller may pass an exact continuity result when its operation proves
    %   one. Otherwise continuity is recomputed over every shared face, since
    %   algebra can cancel a jump even when an input was discontinuous. The
    %   prepared struct avoids repeating public source parsing.

    if nargin < 4
        rb = [];
    end
    if nargin < 5 || isempty(summary)
        summary = "coefficient-backed";
    end
    if nargin < 7 || isempty(sz)
        firstSubs = ones(1, numel(grid));
        firstLeaf = helper.cellGet(vals, firstSubs);
        sz = size(firstLeaf{1});
    end
    if nargin < 6 || isempty(isCont)
        nCell = cellfun(@numel, grid) - 1;
        isCont = helper.chkCont(vals, nCell, deg);
    end
    if nargin < 8
        validationMode = "fast";
    end
    if nargin < 9 || isempty(numRateRows)
        numRateRows = 0;
    end
    % Assign cell-valued fields separately: struct(Name, value) would expand
    % GRID or VALS as a struct array instead of preserving their cell trees.
    init = struct;
    init.PdmatInternal = true;
    init.Grid = grid;
    init.MatrixSize = sz;
    init.Degree = deg;
    init.LocalValues = vals;
    init.IsContinuous = isCont;
    init.ContainsDecision = false;
    init.NumRateRows = numRateRows;
    init.RateBounds = rb;
    init.SourceSummary = summary;
    init.FunctionHandle = [];
    init.ValidationMode = validationMode;
    out = pdmat(init);
end
