function out = applySparsePutinar(obj, varargin)
    %APPLYSPARSEPUTINAR Apply a tensor-window Putinar box certificate.
    %
    %   Syntax:
    %     out = obj.applySparsePutinar()
    %     out = obj.applySparsePutinar(cliqueSize)
    %     out = obj.applySparsePutinar(cliqueSize, order)
    %     out = obj.applySparsePutinar(..., ValidationMode=mode)
    %
    %   Arguments:
    %     cliqueSize - Positive integer tensor-window side length; default 2.
    %     order      - Optional scalar shorthand or ell-element absolute order.
    %                  The default is floor(Residual.Degree/2) in one parameter
    %                  and componentwise ceil(Residual.Degree/2) otherwise.
    %     mode       - Optional trailing "fast" or "strict" assembly check.
    %
    %   Output:
    %     out - New pdlmi rebuilt with the selected certificate.
    %
    %   SparsePutinar uses Putinar's exact one-parameter parity form or its
    %   multidimensional empty and singleton generator masks. Every Gram basis
    %   is covered by all axis-aligned sliding tensor windows with side length
    %   min(cliqueSize, degree+1), and each window owns an independent free PSD
    %   block. Coefficients are matched exactly without adding a margin or
    %   calling a solver. The windows group Bernstein Gram-basis labels; they
    %   do not decompose structural sparsity of the polynomial matrix.
    %
    %   CliqueSize=1 returns actual Direct state in one parameter, but remains
    %   SparsePutinar in multiple parameters. Any larger clique size satisfying
    %   cliqueSize >= max(order+1) returns actual dense Putinar state. Other
    %   sizes retain SparsePutinar state. Every physical cell and active rate
    %   row is independent, as is every column-major entry of an entry-wise
    %   inequality. Reapplication starts from Residual and replaces any earlier
    %   certificate selection.
    %
    %   Invalid sizes raise pdlmi:InvalidCliqueSize. Invalid orders raise
    %   pdlmi:InvalidSparsePutinarOrder, and insufficient orders raise
    %   pdlmi:SparsePutinarOrderTooLow. Coefficient equality raises
    %   pdlmi:UnsupportedEqualityCertificate before size or order validation.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric", Degree=4);
    %     direct = P >= 0;
    %     sparse = direct.applySparsePutinar(2, 2);

    if obj.Relation == "=="
        error("pdlmi:UnsupportedEqualityCertificate", ...
            "Coefficient equality supports direct assembly only.");
    end
    [args, validationMode] = parseApplyValidation(varargin);
    if numel(args) > 2
        error("pdlmi:InvalidApplyOptions", ...
            "Too many positional inputs were supplied.");
    end
    if isempty(args)
        cliqueSize = 2;
    else
        cliqueSize = args{1};
    end
    cliqueSize = chkCliqueSize(cliqueSize);
    if numel(args) < 2
        order = chkSparsePutinarOrder(obj.Residual);
    else
        order = chkSparsePutinarOrder(obj.Residual, args{2});
    end

    out = pdlmi(obj.Residual, obj.Relation, ...
        UseSparsePutinar=true, CliqueSize=cliqueSize, ...
        SparsePutinarOrder=order, ValidationMode=validationMode);
end
