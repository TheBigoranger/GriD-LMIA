function data = asData(grid, val, reqSize, errId)
    %ASDATA Convert an operand into coefficient data on the target grid.
    %
    %   Syntax:
    %     data = asData(grid, val, reqSize, errId)
    %
    %   Arguments:
    %     grid    - Target common-refinement grid.
    %     val     - Numeric or coefficient-backed pdmat operand.
    %     reqSize - Required matrix size, or empty to infer it.
    %     errId   - Operation-specific validation identifier.
    %
    %   Output:
    %     data - Normalized size, degree, LocalValues, and continuity metadata.
    %
    %   Example (called from an @pdmat method):
    %     grid = {[0 1]};
    %     data = asData(grid, 2, [1 1], "pdmat:InvalidOperand");
    %     data.MatrixSize
    %
    %   Numeric operands become degree-0 coefficient data on grid. Coefficient-
    %   backed pdmat operands are reused directly when their grid already matches
    %   grid, or re-expressed on grid for same-bound common-refinement algebra.

    info = helper.mkGrid(grid, "pdmat");

    if isa(val, "pdmat")
        % Function-only objects carry exact evaluators, not Bernstein evidence.
        if val.SourceSummary == "function"
            error("pdmat:FunctionOnlyAlgebra", ...
                "Function-backed pdmat objects need explicit Bernstein coefficient evidence for this operation.");
        end
        if ~isempty(reqSize) && ~isequal(val.MatrixSize, reqSize)
            error(errId, "pdmat matrix sizes are incompatible for this operation.");
        end
        data.MatrixSize = val.MatrixSize;
        data.Degree = val.Degree;

        same = numel(info.Vectors) == numel(val.GridInfo.Vectors);
        if same
            for k = 1:numel(info.Vectors)
                same = same && isequal(info.Vectors{k}, val.GridInfo.Vectors{k});
            end
        end
        if same
            data.LocalValues = val.LocalValues;
        else
            % Re-sampling through evaluate keeps subdivision local to pdmat algebra.
            data.LocalValues = fitVals(info, val.Degree, val.MatrixSize, @(pt) evaluate(val, pt));
        end
        data.IsContinuous = val.IsContinuous;
        return
    end

    % Numeric operands are constant over every physical cell on the target grid.
    helper.chk(val, errId, "Numeric operands must be nonempty finite real matrices.", ...
        "numeric", "real", "finite", "matrix", "nonempty");

    if isempty(reqSize)
        mat = val;
    elseif isscalar(val)
        mat = repmat(val, reqSize);
    elseif isequal(size(val), reqSize)
        mat = val;
    else
        error(errId, "Numeric operand size is incompatible for this operation.");
    end

    data.MatrixSize = size(mat);
    data.Degree = 0;
    nCell = info.NumNodes - 1;
    data.LocalValues = helper.mkNest(nCell, @(~) {mat});
    data.IsContinuous = true;
end
