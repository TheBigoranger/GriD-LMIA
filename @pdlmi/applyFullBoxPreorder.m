function out = applyFullBoxPreorder(obj, order)
    %APPLYFULLBOXPREORDER Apply a cell-local full box preordering certificate.
    %
    %   out = obj.applyFullBoxPreorder() chooses the smallest admissible
    %   absolute order. out = obj.applyFullBoxPreorder(r) selects order r.
    %   Reapplication starts from Residual, so it replaces Pólya or an earlier
    %   full-box selection rather than compounding it.
    %
    %   The default is floor(m/2) for one parameter and ceil(m/2) otherwise,
    %   where m is the residual degree. Each physical cell and active rate row
    %   receives independent PSD Gram blocks. For multiple parameters, the
    %   certificate includes every subset product of the box generators
    %   alpha_s(1-alpha_s); it is not a general Putinar or general-domain SOS
    %   relaxation. No positivity margin is added.
    %
    %   Invalid orders raise pdlmi:InvalidFullBoxOrder; an integer below the
    %   parity/dimension minimum raises pdlmi:FullBoxOrderTooLow.

    if nargin < 2
        order = validateFullBoxOrder(obj.Residual);
    else
        order = validateFullBoxOrder(obj.Residual, order);
    end

    out = pdlmi(obj.Residual, obj.Relation, ...
        UseFullBoxPreorder=true, FullBoxOrder=order);
end
