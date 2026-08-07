function [targetDeg, specs] = putSpec(expr, order)
    %PUTSPEC Define the Putinar parity and generator-mask convention.
    %
    %   Syntax:
    %     [targetDeg, specs] = putSpec(expr, order)
    %
    %   Arguments:
    %     expr  - Residual object supplying parameter count and degree.
    %     order - Absolute 1-by-ell Putinar Gram order.
    %
    %   Output:
    %     targetDeg - Bernstein degree used for exact coefficient matching.
    %     specs     - Cell table; column one is Gram degree, column two stores
    %                 alpha and one-minus-alpha generator powers.
    %
    %   Example:
    %     order = chkOrder(expr, "put");
    %     [targetDeg, specs] = putSpec(expr, order);
    %
    %   In one parameter the Putinar certificate uses the same parity split as
    %   the full-box convention. In multiple parameters it uses the constant
    %   term and one axis generator per parameter, all matched at degree
    %   2*order.
    nPar = expr.npar();
    if nPar == 1
        [targetDeg, specs] = boxSpec(expr, order);
        return
    end
    targetDeg = 2 .* order;
    masks = [zeros(1, nPar); eye(nPar)];
    specs = cell(size(masks, 1), 2);
    for k = 1:size(masks, 1)
        specs{k, 1} = order - masks(k, :);
        specs{k, 2} = [masks(k, :); masks(k, :)];
    end
end
