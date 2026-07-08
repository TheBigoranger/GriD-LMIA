classdef dplmi
    %DPLMI Cell-local YALMIP constraints for DP-LMI expressions.
    %
    %   Syntax:
    %     C = dplmi(expr, "<=")
    %     C = dplmi(expr, ">=", relaxLemma=false, UsePolya=false)
    %
    %   Example:
    %     P = dpvar(2, {[0 1]}, "symmetric");
    %     C = dplmi(P, "<=");
    %
    %   This first slice assembles direct coefficient-wise constraints.
    %   Relaxation lemma and Polya modes are reserved options only.

    properties (SetAccess = private)
        Constraints
        RelaxLemma
        UsePolya
        PolyaDegree
    end

    methods
        function obj = dplmi(expr, relation, options)
            arguments
                expr dpvar
                relation (1, 1) string {mustBeMember(relation, ["<=", ">="])}
                options.relaxLemma (1, 1) logical = false
                options.UsePolya (1, 1) logical = false
                options.PolyaDegree = 0
            end

            pDeg = double(helper.chk(options.PolyaDegree, ...
                "dplmi:InvalidPolyaDegree", ...
                "PolyaDegree must be a nonnegative integer scalar.", ...
                "numeric", "real", "finite", "integer", "nonnegative", "scalar"));
            if options.relaxLemma
                error("dplmi:UnsupportedRelaxLemma", ...
                    "relaxLemma=true is reserved but unsupported in this dplmi slice.");
            end
            if options.UsePolya || pDeg > 0
                error("dplmi:UnsupportedPolya", ...
                    "UsePolya=true and PolyaDegree>0 are reserved but unsupported in this dplmi slice.");
            end

            obj.RelaxLemma = options.relaxLemma;
            obj.UsePolya = options.UsePolya;
            obj.PolyaDegree = pDeg;
            obj.Constraints = buildDirect(expr, relation);
        end
    end
end

function cons = buildDirect(expr, relation)
    if expr.MatrixSize(1) ~= expr.MatrixSize(2)
        error("dplmi:InvalidMatrixSize", ...
            "DP-LMI constraints require square dpvar coefficient matrices.");
    end

    cells = expr.cells();
    cons = {};
    zero = zeros(expr.MatrixSize);
    for c = 1:size(cells, 1)
        coeffs = expr.coeffs(cells(c, :));
        for row = 1:size(coeffs, 1)
            for k = 1:size(coeffs, 2)
                mat = coeffs{row, k};
                chkSym(mat);
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

function chkSym(mat)
    if ~isequal(size(mat, 1), size(mat, 2))
        error("dplmi:InvalidMatrixSize", ...
            "DP-LMI constraints require square coefficient matrices.");
    end
    if isa(mat, "sdpvar")
        if ~ishermitian(mat)
            error("dplmi:NonSymmetricExpression", ...
                "DP-LMI constraints require symmetric or Hermitian coefficient matrices.");
        end
        return
    end

    if norm(mat - mat', inf) > 1e-10
        error("dplmi:NonSymmetricExpression", ...
            "DP-LMI constraints require symmetric or Hermitian coefficient matrices.");
    end
end
