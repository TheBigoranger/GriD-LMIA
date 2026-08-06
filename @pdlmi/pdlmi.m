classdef pdlmi
    %PDLMI Cell-local YALMIP constraints for PD-LMI expressions.
    %
    %   Syntax:
    %     C = pdlmi(expr, relation)
    %     C = pdlmi(expr, "==")
    %     C = pdlmi(expr, relation, "UsePolya")
    %     C = pdlmi(expr, relation, UsePolya=true, PolyaDegree=d)
    %     C = pdlmi(expr, relation, "UsePolya", "PolyaDegree", d)
    %     C = pdlmi(expr, relation, "UseFullBoxPreorder")
    %     C = pdlmi(expr, relation, FullBoxOrder=r)
    %     C = pdlmi(expr, relation, "UsePutinar")
    %     C = pdlmi(expr, relation, UsePutinar=true, PutinarOrder=r)
    %     C = pdlmi(expr, relation, PutinarOrder=r)
    %     C = pdlmi(expr, relation, "UseSparsePutinar")
    %     C = pdlmi(expr, relation, UseSparsePutinar=true, CliqueSize=b)
    %     C = pdlmi(expr, relation, CliqueSize=b)
    %     C = pdlmi(expr, relation, CliqueSize=b, SparsePutinarOrder=r)
    %     C = pdlmi(expr, relation, "UseSparseFullBoxPreorder")
    %     C = pdlmi(expr, relation, UseSparseFullBoxPreorder=true, BandWidth=b)
    %     C = pdlmi(expr, relation, BandWidth=b)
    %     C = pdlmi(expr, relation, BandWidth=b, SparseFullBoxOrder=r)
    %
    %   Arguments:
    %     expr     - pdvar residual, or pdmat residual for an inequality.
    %     relation - "<=", ">=", or "==" applied to assembled coefficients.
    %     options  - One optional inequality certificate selection. Sparse
    %                Putinar uses UseSparsePutinar, SparsePutinarOrder, and
    %                CliqueSize. Sparse full-box uses
    %                UseSparseFullBoxPreorder, SparseFullBoxOrder, and
    %                BandWidth.
    %
    %   Output:
    %     C - Constraint wrapper retaining the residual and assembly settings;
    %         C.toYalmip() returns the assembled YALMIP constraints.
    %
    %   Direct assembly is the default. Inequality classification scans every
    %   coefficient of the original residual across all physical cells and
    %   rate rows. A square residual is semidefinite only when every coefficient
    %   is Hermitian (numeric tolerance 1e-10); otherwise the entire inequality
    %   is entry-wise and issues pdlmi:ElementwiseInequality once per newly
    %   constructed wrapper. Equality is entry-wise and direct-only; supplying
    %   a certificate raises pdlmi:UnsupportedEqualityCertificate.
    %
    %   Pólya uses a nonnegative degree increment; Putinar, SparsePutinar,
    %   sparse full-box, and full-box use absolute Gram orders. Each accepts
    %   scalar uniform shorthand or an ell-element vector and stores a
    %   1-by-ell row. The five relaxations are mutually
    %   exclusive, operate independently per physical cell and rate row, and
    %   add no implicit positivity margin. Entry-wise Gram certificates are
    %   also independent for every MATLAB column-major matrix entry. Apply
    %   methods rebuild from Residual, so a new selection replaces the previous
    %   one.
    %
    %   For a known pdmat inequality, Direct and Pólya export one logical
    %   sufficient certificate using absolute tolerance 1e-10. A false export
    %   warns with pdlmi:InconclusiveCertificate because coefficient failure
    %   does not prove continuous-domain violation or indefiniteness. Gram
    %   certificates still export YALMIP constraints with auxiliary variables.
    %   Function-only pdmat residuals and pdmat equality are unsupported.
    %
    %   SparsePutinar defaults to CliqueSize=2 and the Putinar
    %   dimension-dependent order. CliqueSize=1 returns actual Direct state in
    %   one parameter, but remains SparsePutinar in multiple parameters. Any
    %   larger size satisfying CliqueSize >= max(SparsePutinarOrder+1) returns
    %   actual dense Putinar state. Intermediate sizes use free PSD blocks on
    %   every sliding tensor window of Putinar's parity or empty/singleton
    %   Gram bases, with exact Bernstein coefficient matching. These windows
    %   group Bernstein basis labels rather than structurally sparse matrix
    %   entries.
    %
    %   CliqueSize or SparsePutinarOrder alone enables SparsePutinar. Explicit
    %   UseSparsePutinar=false conflicts with either parameter. Invalid sizes
    %   and orders raise pdlmi:InvalidCliqueSize and
    %   pdlmi:InvalidSparsePutinarOrder; an order below the
    %   dimension-dependent minimum raises pdlmi:SparsePutinarOrderTooLow.
    %
    %   Sparse full-box defaults to BandWidth=2. Its default order is
    %   floor(expr.Degree/2) for one parameter and ceil(expr.Degree/2)
    %   otherwise. Width one always returns actual Direct state. Above that
    %   endpoint, a width spanning every order axis returns actual FullBox
    %   state; equivalently BandWidth >= max(SparseFullBoxOrder+1).
    %   Intermediate widths use free PSD blocks on every axis-aligned
    %   tensor-basis window and exact Bernstein coefficient matching. In one
    %   parameter, widths two and three give block-tridiagonal and
    %   block-pentadiagonal Gram support. Larger widths form a nested sufficient
    %   hierarchy, but strict improvement is not guaranteed.
    %
    %   BandWidth or SparseFullBoxOrder alone enables sparse full-box.
    %   Explicit UseSparseFullBoxPreorder=false conflicts with either parameter.
    %   Invalid widths and orders raise pdlmi:InvalidBandWidth and
    %   pdlmi:InvalidSparseFullBoxOrder; an order below the dimension-dependent
    %   minimum raises pdlmi:SparseFullBoxOrderTooLow.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric");
    %     direct = pdlmi(P, "<=");
    %     polya1 = pdlmi(P, "<=", "UsePolya");
    %     polya2 = direct.applyPolya(2);
    %     directPos = P >= 0;
    %     putinar = directPos.applyPutinar(1);
    %     sparsePutinar = directPos.applySparsePutinar(2, 2);
    %     preorder = directPos.applyFullBoxPreorder();
    %     sparse = directPos.applySparseFullBoxPreorder(2);
    %     entrywise = pdvar(3, 2, {[0 1]}) >= 0;
    %     equality = P == eye(2);

    properties (SetAccess = private)
        Constraints
        Residual
        Relation
        UsePolya
        PolyaDegree
        UseFullBoxPreorder
        FullBoxOrder
        UsePutinar
        PutinarOrder
        UseSparsePutinar
        SparsePutinarOrder
        CliqueSize
        UseSparseFullBoxPreorder
        SparseFullBoxOrder
        BandWidth
    end

    methods
        function obj = pdlmi(expr, relation, varargin)
            if ~(isa(expr, "pdvar") || isa(expr, "pdmat"))
                error("pdlmi:InvalidExpression", ...
                    "The pdlmi residual must be a pdvar or pdmat expression.");
            end
            if ~((ischar(relation) && isrow(relation) && ~isempty(relation)) || ...
                    (isstring(relation) && isscalar(relation) && ~ismissing(relation)))
                error("pdlmi:InvalidRelation", ...
                    "relation must be the scalar string '<=', '>=', or '=='.");
            end
            relation = string(relation);
            if ~isscalar(relation) || ~any(relation == ["<=", ">=", "=="])
                error("pdlmi:InvalidRelation", ...
                    "relation must be the scalar string '<=', '>=', or '=='.");
            end
            if isa(expr, "pdmat") && relation == "=="
                error("pdlmi:UnsupportedPdmatEquality", ...
                    "Coefficient equality remains supported only for pdvar residuals.");
            end
            if isa(expr, "pdmat") && expr.SourceSummary == "function"
                error("pdlmi:MissingCoefficientEvidence", ...
                    "Function-only pdmat residuals need Bernstein coefficient evidence.");
            end

            nPar = expr.npar();
            opts = parseOpts(relation == "==", nPar, varargin{:});
            comparisonMode = classifyComparison(expr, relation);
            obj.Residual = expr;
            obj.Relation = relation;
            obj.UsePolya = opts.UsePolya;
            obj.PolyaDegree = opts.PolyaDegree;
            obj.UseFullBoxPreorder = opts.UseFullBoxPreorder;
            obj.FullBoxOrder = opts.FullBoxOrder;
            obj.UsePutinar = opts.UsePutinar;
            obj.PutinarOrder = opts.PutinarOrder;
            obj.UseSparsePutinar = false;
            obj.SparsePutinarOrder = zeros(1, nPar);
            obj.CliqueSize = 0;
            obj.UseSparseFullBoxPreorder = false;
            obj.SparseFullBoxOrder = zeros(1, nPar);
            obj.BandWidth = 0;
            if opts.UseFullBoxPreorder
                if opts.FullBoxOrderSpecified
                    opts.FullBoxOrder = chkFullBoxOrder(expr, ...
                        opts.FullBoxOrder);
                else
                    opts.FullBoxOrder = chkFullBoxOrder(expr);
                end
                obj.FullBoxOrder = opts.FullBoxOrder;
                obj.Constraints = mkFullBoxCons(expr, ...
                    relation, opts.FullBoxOrder, comparisonMode, ...
                    opts.ValidationMode);
            elseif opts.UsePutinar
                if opts.PutinarOrderSpecified
                    opts.PutinarOrder = chkPutinarOrder(expr, ...
                        opts.PutinarOrder);
                else
                    opts.PutinarOrder = chkPutinarOrder(expr);
                end
                obj.PutinarOrder = opts.PutinarOrder;
                obj.Constraints = mkPutinarCons(expr, relation, ...
                    opts.PutinarOrder, comparisonMode, ...
                    opts.ValidationMode);
            elseif opts.UseSparsePutinar
                if opts.SparsePutinarOrderSpecified
                    order = chkSparsePutinarOrder(expr, ...
                        opts.SparsePutinarOrder);
                else
                    order = chkSparsePutinarOrder(expr);
                end
                cliqueSize = chkCliqueSize(opts.CliqueSize);

                % Size one has a family-specific lower endpoint; larger
                % saturated windows recover the authoritative dense Putinar.
                if cliqueSize == 1 && nPar == 1
                    obj.Constraints = mkCoeffCons(expr, relation, ...
                        false, 0, comparisonMode, opts.ValidationMode);
                elseif cliqueSize > 1 && all(cliqueSize >= order + 1)
                    obj.UsePutinar = true;
                    obj.PutinarOrder = order;
                    obj.Constraints = mkPutinarCons(expr, relation, ...
                        order, comparisonMode, opts.ValidationMode);
                else
                    obj.UseSparsePutinar = true;
                    obj.SparsePutinarOrder = order;
                    obj.CliqueSize = cliqueSize;
                    obj.Constraints = mkSparsePutinarCons(expr, relation, ...
                        order, cliqueSize, comparisonMode, ...
                        opts.ValidationMode);
                end
            elseif opts.UseSparseFullBoxPreorder
                if opts.SparseFullBoxOrderSpecified
                    order = chkSparseFullBoxOrder(expr, ...
                        opts.SparseFullBoxOrder);
                else
                    order = chkSparseFullBoxOrder(expr);
                end
                bandWidth = chkBandWidth(opts.BandWidth);

                % Canonical endpoints preserve the established public states
                % and avoid auxiliary Gram variables when they add no freedom.
                if bandWidth == 1
                    obj.Constraints = mkCoeffCons(expr, relation, ...
                        false, 0, comparisonMode, opts.ValidationMode);
                elseif all(bandWidth >= order + 1)
                    obj.UseFullBoxPreorder = true;
                    obj.FullBoxOrder = order;
                    obj.Constraints = mkFullBoxCons(expr, relation, ...
                        order, comparisonMode, opts.ValidationMode);
                else
                    obj.UseSparseFullBoxPreorder = true;
                    obj.SparseFullBoxOrder = order;
                    obj.BandWidth = bandWidth;
                    obj.Constraints = mkSparseFullBoxCons(expr, relation, ...
                        order, bandWidth, comparisonMode, ...
                        opts.ValidationMode);
                end
            else
                obj.Constraints = mkCoeffCons(expr, relation, ...
                    opts.UsePolya, opts.PolyaDegree, comparisonMode, ...
                    opts.ValidationMode);
            end
            if comparisonMode == "elementwise"
                warning("pdlmi:ElementwiseInequality", ...
                    "The residual is non-square or has a non-Hermitian coefficient; the inequality is assembled entry-wise.");
            end
        end

        out = applyPolya(obj, varargin)
        out = applyFullBoxPreorder(obj, varargin)
        out = applyPutinar(obj, varargin)
        out = applySparsePutinar(obj, varargin)
        out = applySparseFullBoxPreorder(obj, varargin)
    end
end

function mode = classifyComparison(expr, relation)
    %CLASSIFYCOMPARISON Select one global mode from original coefficients.
    %   Scan every cell, rate row, and coefficient; one fallback classifies the
    %   complete original residual as entry-wise.

    if relation == "=="
        mode = "equality";
        return
    end

    if expr.MatrixSize(1) ~= expr.MatrixSize(2)
        mode = "elementwise";
        return
    end

    mode = "semidefinite";
    cells = expr.cells();
    vals = expr.LocalValues;
    for c = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(c, :));
        for row = 1:size(coeffs, 1)
            for k = 1:size(coeffs, 2)
                mat = coeffs{row, k};
                if isa(mat, "sdpvar")
                    isHermitian = ishermitian(mat);
                else
                    isHermitian = norm(mat - mat', inf) <= 1e-10;
                end
                if ~isHermitian
                    mode = "elementwise";
                    return
                end
            end
        end
    end
end

function opts = parseOpts(isEquality, nPar, varargin)
    %PARSEOPTS Normalize selector flags and relaxation-specific orders.
    %   Order-only forms enable their relaxation; conflicting families and
    %   explicit false-plus-parameter inputs are rejected before assembly.

    zeroOrder = zeros(1, nPar);
    opts = struct("UsePolya", false, "PolyaDegree", zeroOrder, ...
        "UseFullBoxPreorder", false, "FullBoxOrder", zeroOrder, ...
        "FullBoxOrderSpecified", false, "UsePutinar", false, ...
        "PutinarOrder", zeroOrder, "PutinarOrderSpecified", false, ...
        "UseSparsePutinar", false, "SparsePutinarOrder", zeroOrder, ...
        "SparsePutinarOrderSpecified", false, "CliqueSize", 0, ...
        "UseSparseFullBoxPreorder", false, "SparseFullBoxOrder", zeroOrder, ...
        "SparseFullBoxOrderSpecified", false, "BandWidth", 0, ...
        "ValidationMode", "fast");
    seen = struct("UsePolya", false, "PolyaDegree", false, ...
        "UseFullBoxPreorder", false, "FullBoxOrder", false, ...
        "UsePutinar", false, "PutinarOrder", false, ...
        "UseSparsePutinar", false, "SparsePutinarOrder", false, ...
        "CliqueSize", false, ...
        "UseSparseFullBoxPreorder", false, ...
        "SparseFullBoxOrder", false, "BandWidth", false, ...
        "ValidationMode", false);
    k = 1;
    while k <= numel(varargin)
        rawName = varargin{k};
        if ~((ischar(rawName) && isrow(rawName) && ~isempty(rawName)) || ...
                (isstring(rawName) && isscalar(rawName) && ~ismissing(rawName)))
            error("pdlmi:InvalidOptions", ...
                "pdlmi option names must be strings or character vectors.");
        end
        name = string(rawName);
        if ~any(name == ["UsePolya", "PolyaDegree", ...
                "UseFullBoxPreorder", "FullBoxOrder", ...
                "UsePutinar", "PutinarOrder", ...
                "UseSparsePutinar", "SparsePutinarOrder", "CliqueSize", ...
                "UseSparseFullBoxPreorder", "SparseFullBoxOrder", ...
                "BandWidth", "ValidationMode"])
            error("pdlmi:UnknownOption", "Unsupported pdlmi option: %s.", name);
        end
        if isEquality && name ~= "ValidationMode"
            error("pdlmi:UnsupportedEqualityCertificate", ...
                "Coefficient equality supports direct assembly only.");
        end
        if seen.(char(name))
            error("pdlmi:DuplicateOption", ...
                "pdlmi option %s may be supplied only once.", name);
        end
        seen.(char(name)) = true;

        % Relaxation selector flags may appear without an explicit value.
        if any(name == ["UsePolya", "UseFullBoxPreorder", ...
                "UsePutinar", "UseSparsePutinar", ...
                "UseSparseFullBoxPreorder"]) && ...
                (k == numel(varargin) || ...
                ((ischar(varargin{k + 1}) && isrow(varargin{k + 1}) && ...
                ~isempty(varargin{k + 1})) || ...
                (isstring(varargin{k + 1}) && isscalar(varargin{k + 1}) && ...
                ~ismissing(varargin{k + 1}))))
            opts.(char(name)) = true;
            k = k + 1;
            continue
        end
        if k == numel(varargin)
            if name == "ValidationMode"
                error("pdlmi:InvalidValidationMode", ...
                    "ValidationMode requires the scalar text 'fast' or 'strict'.");
            end
            error("pdlmi:InvalidOptions", ...
                "pdlmi option %s requires a value.", name);
        end
        if name ~= "ValidationMode" && ...
                ((ischar(varargin{k + 1}) && isrow(varargin{k + 1}) && ...
                ~isempty(varargin{k + 1})) || ...
                (isstring(varargin{k + 1}) && isscalar(varargin{k + 1}) && ...
                ~ismissing(varargin{k + 1})))
            nextName = string(varargin{k + 1});
            if any(nextName == ["UsePolya", "PolyaDegree", ...
                    "UseFullBoxPreorder", "FullBoxOrder", ...
                    "UsePutinar", "PutinarOrder", ...
                    "UseSparsePutinar", "SparsePutinarOrder", ...
                    "CliqueSize", ...
                    "UseSparseFullBoxPreorder", "SparseFullBoxOrder", ...
                    "BandWidth", "ValidationMode"])
                error("pdlmi:InvalidOptions", ...
                    "pdlmi option %s requires a value.", name);
            end
            if ~any(name == ["PutinarOrder", "SparsePutinarOrder", ...
                    "CliqueSize", "SparseFullBoxOrder", "BandWidth"])
                error("pdlmi:UnknownOption", ...
                    "Unsupported pdlmi option: %s.", nextName);
            end
        end
        val = varargin{k + 1};
        switch name
            case "UsePolya"
                if ~islogical(val) || ~isscalar(val)
                    error("pdlmi:InvalidUsePolya", ...
                        "UsePolya must be a logical scalar.");
                end
                opts.UsePolya = val;
            case "PolyaDegree"
                opts.PolyaDegree = helper.normalizeDegree(val, nPar, ...
                    "pdlmi:InvalidPolyaDegree", "PolyaDegree");
            case "UseFullBoxPreorder"
                if ~islogical(val) || ~isscalar(val)
                    error("pdlmi:InvalidUseFullBoxPreorder", ...
                        "UseFullBoxPreorder must be a logical scalar.");
                end
                opts.UseFullBoxPreorder = val;
            case "FullBoxOrder"
                opts.FullBoxOrder = helper.normalizeDegree(val, nPar, ...
                    "pdlmi:InvalidFullBoxOrder", "FullBoxOrder");
                opts.FullBoxOrderSpecified = true;
            case "UsePutinar"
                if ~islogical(val) || ~isscalar(val)
                    error("pdlmi:InvalidUsePutinar", ...
                        "UsePutinar must be a logical scalar.");
                end
                opts.UsePutinar = val;
            case "PutinarOrder"
                opts.PutinarOrder = helper.normalizeDegree(val, nPar, ...
                    "pdlmi:InvalidPutinarOrder", "PutinarOrder");
                opts.PutinarOrderSpecified = true;
            case "UseSparsePutinar"
                if ~islogical(val) || ~isscalar(val)
                    error("pdlmi:InvalidUseSparsePutinar", ...
                        "UseSparsePutinar must be a logical scalar.");
                end
                opts.UseSparsePutinar = val;
            case "SparsePutinarOrder"
                opts.SparsePutinarOrder = helper.normalizeDegree(val, nPar, ...
                    "pdlmi:InvalidSparsePutinarOrder", ...
                    "SparsePutinarOrder");
                opts.SparsePutinarOrderSpecified = true;
            case "CliqueSize"
                opts.CliqueSize = chkCliqueSize(val);
            case "UseSparseFullBoxPreorder"
                if ~islogical(val) || ~isscalar(val)
                    error("pdlmi:InvalidUseSparseFullBoxPreorder", ...
                        "UseSparseFullBoxPreorder must be a logical scalar.");
                end
                opts.UseSparseFullBoxPreorder = val;
            case "SparseFullBoxOrder"
                opts.SparseFullBoxOrder = helper.normalizeDegree(val, nPar, ...
                    "pdlmi:InvalidSparseFullBoxOrder", ...
                    "SparseFullBoxOrder");
                opts.SparseFullBoxOrderSpecified = true;
            case "BandWidth"
                opts.BandWidth = chkBandWidth(val);
            case "ValidationMode"
                opts.ValidationMode = normalizeValidationMode(val);
        end
        k = k + 2;
    end

    if seen.PolyaDegree && ~seen.UsePolya
        warning("pdlmi:ImplicitUsePolya", ...
            "PolyaDegree was supplied without UsePolya; Polya relaxation is enabled.");
        opts.UsePolya = true;
    elseif seen.UsePolya && ~seen.PolyaDegree
        opts.PolyaDegree = repmat(double(opts.UsePolya), 1, nPar);
    end
    if seen.UsePolya && ~opts.UsePolya && any(opts.PolyaDegree > 0)
        error("pdlmi:ConflictingPolyaOptions", ...
            "UsePolya=false conflicts with a positive PolyaDegree.");
    end
    if seen.FullBoxOrder && ~seen.UseFullBoxPreorder
        opts.UseFullBoxPreorder = true;
    end
    if seen.UsePutinar && ~opts.UsePutinar && seen.PutinarOrder
        error("pdlmi:ConflictingPutinarOptions", ...
            "UsePutinar=false conflicts with an explicit PutinarOrder.");
    end
    if seen.PutinarOrder && ~seen.UsePutinar
        opts.UsePutinar = true;
    end
    if seen.UseSparsePutinar && ~opts.UseSparsePutinar && ...
            (seen.SparsePutinarOrder || seen.CliqueSize)
        error("pdlmi:ConflictingSparsePutinarOptions", ...
            "UseSparsePutinar=false conflicts with SparsePutinar parameters.");
    end
    if (seen.SparsePutinarOrder || seen.CliqueSize) && ...
            ~seen.UseSparsePutinar
        opts.UseSparsePutinar = true;
    end
    if opts.UseSparsePutinar && ~seen.CliqueSize
        opts.CliqueSize = 2;
    end
    if seen.UseSparseFullBoxPreorder && ...
            ~opts.UseSparseFullBoxPreorder && ...
            (seen.SparseFullBoxOrder || seen.BandWidth)
        error("pdlmi:ConflictingSparseFullBoxOptions", ...
            "UseSparseFullBoxPreorder=false conflicts with sparse full-box parameters.");
    end
    if (seen.SparseFullBoxOrder || seen.BandWidth) && ...
            ~seen.UseSparseFullBoxPreorder
        opts.UseSparseFullBoxPreorder = true;
    end
    if opts.UseSparseFullBoxPreorder && ~seen.BandWidth
        opts.BandWidth = 2;
    end
    if sum([opts.UsePolya, opts.UseFullBoxPreorder, opts.UsePutinar, ...
            opts.UseSparsePutinar, ...
            opts.UseSparseFullBoxPreorder]) > 1
        error("pdlmi:ConflictingRelaxations", ...
            "Pólya, Putinar, SparsePutinar, sparse full box, and full box preordering cannot be enabled together.");
    end
end

function mode = normalizeValidationMode(value)
    %NORMALIZEVALIDATIONMODE Validate transient assembly-plan checking.
    if ~((ischar(value) && isrow(value) && ~isempty(value)) || ...
            (isstring(value) && isscalar(value) && ~ismissing(value)))
        error("pdlmi:InvalidValidationMode", ...
            "ValidationMode must be the scalar text 'fast' or 'strict'.");
    end
    mode = lower(string(value));
    if ~any(mode == ["fast", "strict"])
        error("pdlmi:InvalidValidationMode", ...
            "ValidationMode must be the scalar text 'fast' or 'strict'.");
    end
end
