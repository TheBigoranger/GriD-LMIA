function out = applyPutinar(obj, order)
    %APPLYPUTINAR Apply a cell-local Putinar box certificate.
    %
    %   Syntax:
    %     out = obj.applyPutinar()
    %     out = obj.applyPutinar(order)
    %
    %   Arguments:
    %     order - Optional absolute tensor Bernstein Gram order.
    %
    %   Output:
    %     out - New pdlmi rebuilt with the Putinar certificate enabled.
    %
    %   For one parameter, the default order and certificate are the
    %   parity-specific Markov-Lukacs form used by applyFullBoxPreorder.
    %   For two or more parameters, the default order is
    %   ceil(Residual.Degree/2) and the quadratic-module form is used.
    %   Reapplication rebuilds from Residual and replaces any Pólya,
    %   Putinar, or full-box selection.
    %
    %   In every physical cell and active rate row, the sign-normalized target
    %   is represented by the Markov-Lukacs parity form in one parameter, and
    %   by S0 + sum_s alpha_s(1-alpha_s)Ss otherwise. No positivity margin is
    %   inserted and this method does not call a solver. Invalid orders raise
    %   pdlmi:InvalidPutinarOrder; insufficient orders raise
    %   pdlmi:PutinarOrderTooLow.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric", Degree=3);
    %     direct = P >= 0;
    %     putinar = direct.applyPutinar(2);

    if nargin < 2
        order = chkPutinarOrder(obj.Residual);
    else
        order = chkPutinarOrder(obj.Residual, order);
    end

    out = pdlmi(obj.Residual, obj.Relation, ...
        UsePutinar=true, PutinarOrder=order);
end
