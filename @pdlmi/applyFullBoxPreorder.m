function out = applyFullBoxPreorder(obj, order)
    %APPLYFULLBOXPREORDER Apply a cell-local full box preordering certificate.
    %
    %   Syntax:
    %     out = obj.applyFullBoxPreorder()
    %     out = obj.applyFullBoxPreorder(order)
    %
    %   Arguments:
    %     order - Optional admissible absolute certificate order.
    %
    %   Output:
    %     out - New pdlmi rebuilt with full-box preordering enabled.
    %
    %   The no-argument form chooses the smallest admissible absolute order.
    %   Reapplication starts from Residual, so it replaces any Pólya, Putinar,
    %   sparse full-box, or earlier FullBox selection rather than compounding
    %   it.
    %
    %   The default is floor(m/2) for one parameter and ceil(m/2) otherwise,
    %   where m is the residual degree. Each physical cell and active rate row
    %   receives independent PSD Gram blocks; each entry of an entry-wise
    %   inequality gets an independent scalar Gram certificate in MATLAB
    %   column-major order. For multiple parameters, the certificate includes
    %   every subset product of the box generators alpha_s(1-alpha_s); it is not
    %   a general Putinar or general-domain SOS relaxation. No positivity margin
    %   is added.
    %
    %   Invalid orders raise pdlmi:InvalidFullBoxOrder; an integer below the
    %   parity/dimension minimum raises pdlmi:FullBoxOrderTooLow. Coefficient
    %   equality raises pdlmi:UnsupportedEqualityCertificate before order
    %   validation.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric", Degree=2);
    %     direct = P >= 0;
    %     preorder = direct.applyFullBoxPreorder(1);

    if obj.Relation == "=="
        error("pdlmi:UnsupportedEqualityCertificate", ...
            "Coefficient equality supports direct assembly only.");
    end
    if nargin < 2
        order = chkFullBoxOrder(obj.Residual);
    else
        order = chkFullBoxOrder(obj.Residual, order);
    end

    out = pdlmi(obj.Residual, obj.Relation, ...
        UseFullBoxPreorder=true, FullBoxOrder=order);
end
