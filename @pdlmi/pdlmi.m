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
    %
    %   Arguments:
    %     expr     - pdvar residual to constrain coefficient-wise.
    %     relation - "<=", ">=", or "==" applied to assembled coefficients.
    %     options  - One optional inequality certificate selection.
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
    %   Pólya uses a nonnegative degree increment; Putinar and full-box use
    %   absolute Gram orders. The three relaxations are mutually exclusive,
    %   operate independently per physical cell and rate row, and add no
    %   implicit positivity margin. Apply methods rebuild from Residual, so a
    %   new selection replaces the previous one.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric");
    %     direct = pdlmi(P, "<=");
    %     polya1 = pdlmi(P, "<=", "UsePolya");
    %     polya2 = direct.applyPolya(2);
    %     directPos = P >= 0;
    %     putinar = directPos.applyPutinar(1);
    %     preorder = directPos.applyFullBoxPreorder();
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
    end

    methods
        function obj = pdlmi(expr, relation, varargin)
            if ~isa(expr, "pdvar")
                error("pdlmi:InvalidExpression", ...
                    "The pdlmi residual must be a pdvar expression.");
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

            opts = parseOpts(relation == "==", varargin{:});
            mode = classifyComparison(expr, relation);
            obj.Residual = expr;
            obj.Relation = relation;
            obj.UsePolya = opts.UsePolya;
            obj.PolyaDegree = opts.PolyaDegree;
            obj.UseFullBoxPreorder = opts.UseFullBoxPreorder;
            obj.FullBoxOrder = opts.FullBoxOrder;
            obj.UsePutinar = opts.UsePutinar;
            obj.PutinarOrder = opts.PutinarOrder;
            if opts.UseFullBoxPreorder
                if opts.FullBoxOrderSpecified
                    opts.FullBoxOrder = chkFullBoxOrder(expr, ...
                        opts.FullBoxOrder);
                else
                    opts.FullBoxOrder = chkFullBoxOrder(expr);
                end
                obj.FullBoxOrder = opts.FullBoxOrder;
                obj.Constraints = mkFullBoxCons(expr, ...
                    relation, opts.FullBoxOrder, mode);
            elseif opts.UsePutinar
                if opts.PutinarOrderSpecified
                    opts.PutinarOrder = chkPutinarOrder(expr, ...
                        opts.PutinarOrder);
                else
                    opts.PutinarOrder = chkPutinarOrder(expr);
                end
                obj.PutinarOrder = opts.PutinarOrder;
                obj.Constraints = mkPutinarCons(expr, relation, ...
                    opts.PutinarOrder, mode);
            else
                obj.Constraints = mkCoeffCons(expr, relation, ...
                    opts.UsePolya, opts.PolyaDegree, mode);
            end
            if mode == "elementwise"
                warning("pdlmi:ElementwiseInequality", ...
                    "The residual is non-square or has a non-Hermitian coefficient; the inequality is assembled entry-wise.");
            end
        end

        out = applyPolya(obj, degreeIncrement)
        out = applyFullBoxPreorder(obj, order)
        out = applyPutinar(obj, order)
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

    mode = "semidefinite";
    cells = expr.cells();
    for c = 1:size(cells, 1)
        coeffs = expr.coeffs(cells(c, :));
        for row = 1:size(coeffs, 1)
            for k = 1:size(coeffs, 2)
                mat = coeffs{row, k};
                if size(mat, 1) ~= size(mat, 2)
                    mode = "elementwise";
                elseif isa(mat, "sdpvar")
                    if ~ishermitian(mat)
                        mode = "elementwise";
                    end
                elseif norm(mat - mat', inf) > 1e-10
                    mode = "elementwise";
                end
            end
        end
    end
end

function opts = parseOpts(isEquality, varargin)
    %PARSEOPTS Normalize selector flags and relaxation-specific orders.
    %   Order-only forms enable their relaxation; conflicting families and
    %   explicit false-plus-order Putinar input are rejected before assembly.

    opts = struct("UsePolya", false, "PolyaDegree", 0, ...
        "UseFullBoxPreorder", false, "FullBoxOrder", 0, ...
        "FullBoxOrderSpecified", false, "UsePutinar", false, ...
        "PutinarOrder", 0, "PutinarOrderSpecified", false);
    seen = struct("UsePolya", false, "PolyaDegree", false, ...
        "UseFullBoxPreorder", false, "FullBoxOrder", false, ...
        "UsePutinar", false, "PutinarOrder", false);
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
                "UsePutinar", "PutinarOrder"])
            error("pdlmi:UnknownOption", "Unsupported pdlmi option: %s.", name);
        end
        if isEquality
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
                "UsePutinar"]) && ...
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
            error("pdlmi:InvalidOptions", ...
                "pdlmi option %s requires a value.", name);
        end
        if (ischar(varargin{k + 1}) && isrow(varargin{k + 1}) && ...
                ~isempty(varargin{k + 1})) || ...
                (isstring(varargin{k + 1}) && isscalar(varargin{k + 1}) && ...
                ~ismissing(varargin{k + 1}))
            nextName = string(varargin{k + 1});
            if any(nextName == ["UsePolya", "PolyaDegree", ...
                    "UseFullBoxPreorder", "FullBoxOrder", ...
                    "UsePutinar", "PutinarOrder"])
                error("pdlmi:InvalidOptions", ...
                    "pdlmi option %s requires a value.", name);
            end
            if name ~= "PutinarOrder"
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
                opts.PolyaDegree = double(helper.chk(val, ...
                    "pdlmi:InvalidPolyaDegree", ...
                    "PolyaDegree must be a finite nonnegative integer scalar.", ...
                    "numeric", "real", "finite", "integer", ...
                        "nonnegative", "scalar"));
            case "UseFullBoxPreorder"
                if ~islogical(val) || ~isscalar(val)
                    error("pdlmi:InvalidUseFullBoxPreorder", ...
                        "UseFullBoxPreorder must be a logical scalar.");
                end
                opts.UseFullBoxPreorder = val;
            case "FullBoxOrder"
                opts.FullBoxOrder = double(helper.chk(val, ...
                    "pdlmi:InvalidFullBoxOrder", ...
                    "FullBoxOrder must be a finite nonnegative integer scalar.", ...
                    "numeric", "real", "finite", "integer", ...
                    "nonnegative", "scalar"));
                opts.FullBoxOrderSpecified = true;
            case "UsePutinar"
                if ~islogical(val) || ~isscalar(val)
                    error("pdlmi:InvalidUsePutinar", ...
                        "UsePutinar must be a logical scalar.");
                end
                opts.UsePutinar = val;
            case "PutinarOrder"
                opts.PutinarOrder = double(helper.chk(val, ...
                    "pdlmi:InvalidPutinarOrder", ...
                    "PutinarOrder must be a finite nonnegative integer scalar.", ...
                    "numeric", "real", "finite", "integer", ...
                    "nonnegative", "scalar"));
                opts.PutinarOrderSpecified = true;
        end
        k = k + 2;
    end

    if seen.PolyaDegree && ~seen.UsePolya
        warning("pdlmi:ImplicitUsePolya", ...
            "PolyaDegree was supplied without UsePolya; Polya relaxation is enabled.");
        opts.UsePolya = true;
    elseif seen.UsePolya && ~seen.PolyaDegree
        opts.PolyaDegree = double(opts.UsePolya);
    end
    if seen.UsePolya && ~opts.UsePolya && opts.PolyaDegree > 0
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
    if sum([opts.UsePolya, opts.UseFullBoxPreorder, opts.UsePutinar]) > 1
        error("pdlmi:ConflictingRelaxations", ...
            "Pólya, Putinar, and full box preordering cannot be enabled together.");
    end
end
