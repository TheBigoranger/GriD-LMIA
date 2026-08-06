function out = applyPutinar(obj, varargin)
    %APPLYPUTINAR Apply a cell-local Putinar box certificate.
    %
    %   Syntax:
    %     out = obj.applyPutinar()
    %     out = obj.applyPutinar(order)
    %
    %   Arguments:
    %     order - Optional scalar shorthand or ell-element absolute Gram order.
    %
    %   Output:
    %     out - New pdlmi rebuilt with the Putinar certificate enabled.
    %
    %   Scalar input expands uniformly; PutinarOrder is stored as a 1-by-ell
    %   row vector. For one parameter, the default order and certificate are the
    %   parity-specific Markov-Lukacs form used by applyFullBoxPreorder.
    %   For two or more parameters, the default/minimum order is componentwise
    %   ceil(Residual.Degree/2), the target degree is 2.*order, and the
    %   quadratic-module form is used.
    %   Reapplication rebuilds from Residual and replaces any Pólya, Putinar,
    %   SparsePutinar, sparse full-box, or FullBox selection.
    %
    %   In every physical cell and active rate row, the sign-normalized target
    %   is represented by the Markov-Lukacs parity form in one parameter, and
    %   by S0 + sum_s alpha_s(1-alpha_s)Ss otherwise. No positivity margin is
    %   inserted and this method does not call a solver. Invalid orders raise
    %   pdlmi:InvalidPutinarOrder; insufficient orders raise
    %   pdlmi:PutinarOrderTooLow. Each entry of an entry-wise inequality gets
    %   an independent scalar Gram certificate in MATLAB column-major order.
    %   Coefficient equality raises pdlmi:UnsupportedEqualityCertificate before
    %   order validation.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric", Degree=3);
    %     direct = P >= 0;
    %     putinar = direct.applyPutinar(2);

    if obj.Relation == "=="
        error("pdlmi:UnsupportedEqualityCertificate", ...
            "Coefficient equality supports direct assembly only.");
    end
    [args, validationMode] = parseApplyValidation(varargin);
    if numel(args) > 1
        error("pdlmi:InvalidApplyOptions", ...
            "Too many positional inputs were supplied.");
    end
    if isempty(args)
        order = chkPutinarOrder(obj.Residual);
    else
        order = chkPutinarOrder(obj.Residual, args{1});
    end

    out = pdlmi(obj.Residual, obj.Relation, ...
        UsePutinar=true, PutinarOrder=order, ...
        ValidationMode=validationMode);
end
