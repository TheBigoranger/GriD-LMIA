classdef dplmi
    %DPLMI Cell-local YALMIP constraints for DP-LMI expressions.
    %
    %   Syntax:
    %     C = dplmi(expr, "<=")
    %     C = dplmi(expr, relation, "UsePolya")
    %     C = dplmi(expr, relation, UsePolya=true, PolyaDegree=d)
    %     C = dplmi(expr, relation, "UsePolya", "PolyaDegree", d)
    %
    %   Direct coefficient-wise assembly is the default. Pólya assembly
    %   elevates the residual by the nonnegative increment PolyaDegree in
    %   every parameter direction, then constrains every elevated coefficient
    %   and active rate row. Bare UsePolya defaults the increment to one.
    %   Supplying PolyaDegree without UsePolya enables Pólya and issues
    %   warning dplmi:ImplicitUsePolya.
    %
    %   Residual retains the original dpvar expression and Relation stores
    %   "<=" or ">=". applyPolya rebuilds from that residual, so selecting a
    %   new increment does not compound an earlier elevation or mutate C.
    %   relaxLemma=true raises dplmi:UnsupportedRelaxLemma. A positive degree
    %   with UsePolya=false raises dplmi:ConflictingPolyaOptions; malformed,
    %   duplicate, unknown, or invalid-degree options also fail explicitly.
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "symmetric");
    %     direct = dplmi(P, "<=");
    %     polya1 = dplmi(P, "<=", "UsePolya");
    %     polya2 = direct.applyPolya(2);

    properties (SetAccess = private)
        Constraints
        Residual
        Relation
        RelaxLemma
        UsePolya
        PolyaDegree
    end

    methods
        function obj = dplmi(expr, relation, varargin)
            if ~isa(expr, "dpvar")
                error("dplmi:InvalidExpression", ...
                    "The dplmi residual must be a dpvar expression.");
            end
            if ~((ischar(relation) && isrow(relation) && ~isempty(relation)) || ...
                    (isstring(relation) && isscalar(relation) && ~ismissing(relation)))
                error("dplmi:InvalidRelation", ...
                    "relation must be the scalar string '<=' or '>='.");
            end
            relation = string(relation);
            if ~isscalar(relation) || ~any(relation == ["<=", ">="])
                error("dplmi:InvalidRelation", ...
                    "relation must be the scalar string '<=' or '>='.");
            end

            opts = parseOptions(varargin{:});
            if opts.relaxLemma
                error("dplmi:UnsupportedRelaxLemma", ...
                    "relaxLemma=true is reserved but unsupported in this dplmi slice.");
            end

            obj.Residual = expr;
            obj.Relation = relation;
            obj.RelaxLemma = opts.relaxLemma;
            obj.UsePolya = opts.UsePolya;
            obj.PolyaDegree = opts.PolyaDegree;
            obj.Constraints = buildConstraints(expr, relation, ...
                opts.UsePolya, opts.PolyaDegree);
        end

        out = applyPolya(obj, degreeIncrement)
    end
end

function opts = parseOptions(varargin)
    opts = struct("relaxLemma", false, "UsePolya", false, ...
        "PolyaDegree", 0);
    seen = struct("relaxLemma", false, "UsePolya", false, ...
        "PolyaDegree", false);
    k = 1;
    while k <= numel(varargin)
        rawName = varargin{k};
        if ~((ischar(rawName) && isrow(rawName) && ~isempty(rawName)) || ...
                (isstring(rawName) && isscalar(rawName) && ~ismissing(rawName)))
            error("dplmi:InvalidOptions", ...
                "dplmi option names must be strings or character vectors.");
        end
        name = string(rawName);
        if ~any(name == ["relaxLemma", "UsePolya", "PolyaDegree"])
            error("dplmi:UnknownOption", "Unsupported dplmi option: %s.", name);
        end
        if seen.(char(name))
            error("dplmi:DuplicateOption", ...
                "dplmi option %s may be supplied only once.", name);
        end
        seen.(char(name)) = true;

        % UsePolya is the only flag that may appear without an explicit value.
        if name == "UsePolya" && ...
                (k == numel(varargin) || ...
                ((ischar(varargin{k + 1}) && isrow(varargin{k + 1}) && ...
                ~isempty(varargin{k + 1})) || ...
                (isstring(varargin{k + 1}) && isscalar(varargin{k + 1}) && ...
                ~ismissing(varargin{k + 1}))))
            opts.UsePolya = true;
            k = k + 1;
            continue
        end
        if k == numel(varargin)
            error("dplmi:InvalidOptions", ...
                "dplmi option %s requires a value.", name);
        end
        if (ischar(varargin{k + 1}) && isrow(varargin{k + 1}) && ...
                ~isempty(varargin{k + 1})) || ...
                (isstring(varargin{k + 1}) && isscalar(varargin{k + 1}) && ...
                ~ismissing(varargin{k + 1}))
            nextName = string(varargin{k + 1});
            if any(nextName == ["relaxLemma", "UsePolya", "PolyaDegree"])
                error("dplmi:InvalidOptions", ...
                    "dplmi option %s requires a value.", name);
            end
            error("dplmi:UnknownOption", ...
                "Unsupported dplmi option: %s.", nextName);
        end
        val = varargin{k + 1};
        switch name
            case "relaxLemma"
                if ~islogical(val) || ~isscalar(val)
                    error("dplmi:InvalidRelaxLemma", ...
                        "relaxLemma must be a logical scalar.");
                end
                opts.relaxLemma = val;
            case "UsePolya"
                if ~islogical(val) || ~isscalar(val)
                    error("dplmi:InvalidUsePolya", ...
                        "UsePolya must be a logical scalar.");
                end
                opts.UsePolya = val;
            case "PolyaDegree"
                opts.PolyaDegree = double(helper.chk(val, ...
                    "dplmi:InvalidPolyaDegree", ...
                    "PolyaDegree must be a finite nonnegative integer scalar.", ...
                    "numeric", "real", "finite", "integer", ...
                    "nonnegative", "scalar"));
        end
        k = k + 2;
    end

    if seen.PolyaDegree && ~seen.UsePolya
        warning("dplmi:ImplicitUsePolya", ...
            "PolyaDegree was supplied without UsePolya; Polya relaxation is enabled.");
        opts.UsePolya = true;
    elseif seen.UsePolya && ~seen.PolyaDegree
        opts.PolyaDegree = double(opts.UsePolya);
    end
    if seen.UsePolya && ~opts.UsePolya && opts.PolyaDegree > 0
        error("dplmi:ConflictingPolyaOptions", ...
            "UsePolya=false conflicts with a positive PolyaDegree.");
    end
end

function cons = buildConstraints(expr, relation, usePolya, pDeg)
    if expr.MatrixSize(1) ~= expr.MatrixSize(2)
        error("dplmi:InvalidMatrixSize", ...
            "DP-LMI constraints require square dpvar coefficient matrices.");
    end

    if usePolya
        vals = expr.elevVals(pDeg);
    else
        vals = expr.LocalValues;
    end
    cells = expr.cells();
    cons = {};
    zero = zeros(expr.MatrixSize);
    for c = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(c, :));
        for row = 1:size(coeffs, 1)
            for k = 1:size(coeffs, 2)
                mat = coeffs{row, k};
                if ~isequal(size(mat, 1), size(mat, 2))
                    error("dplmi:InvalidMatrixSize", ...
                        "DP-LMI constraints require square coefficient matrices.");
                end
                if isa(mat, "sdpvar")
                    if ~ishermitian(mat)
                        error("dplmi:NonSymmetricExpression", ...
                            "DP-LMI constraints require symmetric or Hermitian coefficient matrices.");
                    end
                elseif norm(mat - mat', inf) > 1e-10
                    error("dplmi:NonSymmetricExpression", ...
                        "DP-LMI constraints require symmetric or Hermitian coefficient matrices.");
                end
                % Each row is a rate vertex when rhodiff produced rate rows;
                % ordinary expressions simply have one row.
                if relation == "<="
                    cons{end + 1, 1} = mat <= zero; %#ok<AGROW>
                else
                    cons{end + 1, 1} = mat >= zero; %#ok<AGROW>
                end
            end
        end
    end
end
