function out = mkObj(grid, vals, deg, rb, summary, isCont, sz, validationMode)
    %MKOBJ Rebuild coefficient-backed pdmat data without a user warning.
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
        isCont = chkCont(vals, nCell, deg);
    end
    if nargin < 8
        validationMode = "fast";
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
    init.HasRateDependence = ~isempty(rb);
    init.RateBounds = rb;
    init.SourceSummary = summary;
    init.FunctionHandle = [];
    init.ValidationMode = validationMode;
    out = pdmat(init);
end
