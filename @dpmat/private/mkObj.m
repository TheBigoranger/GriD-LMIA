function out = mkObj(grid, vals, deg)
    %MKOBJ Rebuild coefficient-backed dpmat data without a user warning.
    %
    %   Internal operations still infer continuity from their generated local
    %   coefficients. The prepared struct follows dpvar's private-init pattern
    %   and prevents repeated warnings during algebraic reconstruction.

    [sz, deg, vals, isCont, summary, fh] = mkData(grid, vals, deg);
    % Assign cell-valued fields separately: struct(Name, value) would expand
    % GRID or VALS as a struct array instead of preserving their cell trees.
    init = struct;
    init.DpmatInternal = true;
    init.Grid = grid;
    init.MatrixSize = sz;
    init.Degree = deg;
    init.LocalValues = vals;
    init.IsContinuous = isCont;
    init.SourceSummary = summary;
    init.FunctionHandle = fh;
    out = dpmat(init);
end
