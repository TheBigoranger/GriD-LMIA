classdef pdlmi
    %PDLMI Cell-local YALMIP constraints for DP-LMI expressions.
    %
    %   Syntax:
    %     C = pdlmi(expr, "<=")
    %     C = pdlmi(expr, relation, "UsePolya")
    %     C = pdlmi(expr, relation, UsePolya=true, PolyaDegree=d)
    %     C = pdlmi(expr, relation, "UsePolya", "PolyaDegree", d)
    %
    %   Direct coefficient-wise assembly is the default. Pólya assembly
    %   elevates the residual by the nonnegative increment PolyaDegree in
    %   every parameter direction, then constrains every elevated coefficient
    %   and active rate row. Bare UsePolya defaults the increment to one.
    %   Supplying PolyaDegree without UsePolya enables Pólya and issues
    %   warning pdlmi:ImplicitUsePolya.
    %
    %   applyFullBoxPreorder selects an opt-in full box preordering in each
    %   cell's local Bernstein basis. In one parameter it uses the
    %   parity-specific Markov-Lukacs form; in multiple parameters it includes
    %   one Gram block for every subset product of alpha_s(1-alpha_s). This is
    %   the box-specific preordering, not a general Putinar or general-domain
    %   SOS relaxation. FullBoxOrder is an absolute order, not a degree
    %   increment. Gram variables are independent across physical cells and
    %   active rate rows, and no implicit margin is added.
    %
    %   Residual retains the original pdvar expression and Relation stores
    %   "<=" or ">=". applyPolya rebuilds from that residual, so selecting a
    %   new increment does not compound an earlier elevation or mutate C.
    %   A positive degree with UsePolya=false raises
    %   pdlmi:ConflictingPolyaOptions; malformed, duplicate, unknown, or
    %   invalid options also fail explicitly.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric");
    %     direct = pdlmi(P, "<=");
    %     polya1 = pdlmi(P, "<=", "UsePolya");
    %     polya2 = direct.applyPolya(2);
    %     directPos = P >= 0;
    %     preorder = directPos.applyFullBoxPreorder();

    properties (SetAccess = private)
        Constraints
        Residual
        Relation
        UsePolya
        PolyaDegree
        UseFullBoxPreorder
        FullBoxOrder
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
                    "relation must be the scalar string '<=' or '>='.");
            end
            relation = string(relation);
            if ~isscalar(relation) || ~any(relation == ["<=", ">="])
                error("pdlmi:InvalidRelation", ...
                    "relation must be the scalar string '<=' or '>='.");
            end

            opts = parseOptions(varargin{:});
            obj.Residual = expr;
            obj.Relation = relation;
            obj.UsePolya = opts.UsePolya;
            obj.PolyaDegree = opts.PolyaDegree;
            obj.UseFullBoxPreorder = opts.UseFullBoxPreorder;
            obj.FullBoxOrder = opts.FullBoxOrder;
            if opts.UseFullBoxPreorder
                if opts.FullBoxOrderSpecified
                    opts.FullBoxOrder = validateFullBoxOrder(expr, ...
                        opts.FullBoxOrder);
                else
                    opts.FullBoxOrder = validateFullBoxOrder(expr);
                end
                obj.FullBoxOrder = opts.FullBoxOrder;
                obj.Constraints = buildFullBoxPreorderConstraints(expr, ...
                    relation, opts.FullBoxOrder);
            else
                obj.Constraints = buildCoefficientConstraints(expr, relation, ...
                    opts.UsePolya, opts.PolyaDegree);
            end
        end

        out = applyPolya(obj, degreeIncrement)
        out = applyFullBoxPreorder(obj, order)
    end
end

function opts = parseOptions(varargin)
    opts = struct("UsePolya", false, "PolyaDegree", 0, ...
        "UseFullBoxPreorder", false, "FullBoxOrder", 0, ...
        "FullBoxOrderSpecified", false);
    seen = struct("UsePolya", false, "PolyaDegree", false, ...
        "UseFullBoxPreorder", false, "FullBoxOrder", false);
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
                "UseFullBoxPreorder", "FullBoxOrder"])
            error("pdlmi:UnknownOption", "Unsupported pdlmi option: %s.", name);
        end
        if seen.(char(name))
            error("pdlmi:DuplicateOption", ...
                "pdlmi option %s may be supplied only once.", name);
        end
        seen.(char(name)) = true;

        % Relaxation selector flags may appear without an explicit value.
        if any(name == ["UsePolya", "UseFullBoxPreorder"]) && ...
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
                    "UseFullBoxPreorder", "FullBoxOrder"])
                error("pdlmi:InvalidOptions", ...
                    "pdlmi option %s requires a value.", name);
            end
            error("pdlmi:UnknownOption", ...
                "Unsupported pdlmi option: %s.", nextName);
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
    if opts.UsePolya && opts.UseFullBoxPreorder
        error("pdlmi:ConflictingRelaxations", ...
            "Pólya and full box preordering cannot be enabled together.");
    end
end
