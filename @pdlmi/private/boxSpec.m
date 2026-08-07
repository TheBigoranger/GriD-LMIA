function [targetDeg, specs] = boxSpec(expr, order)
    %BOXSPEC Define the full-box parity and generator-mask convention.
    %
    %   Syntax:
    %     [targetDeg, specs] = boxSpec(expr, order)
    %
    %   Arguments:
    %     expr  - Residual object supplying parameter count and degree.
    %     order - Absolute 1-by-ell full-box Gram order.
    %
    %   Output:
    %     targetDeg - Bernstein degree used for exact coefficient matching.
    %     specs     - Cell table; column one is Gram degree, column two stores
    %                 alpha and one-minus-alpha generator powers.
    %
    %   Example:
    %     order = chkOrder(expr, "box");
    %     [targetDeg, specs] = boxSpec(expr, order);
    %
    %   The one-parameter case follows the even/odd parity split. The
    %   multidimensional case enumerates every box-generator mask, so full-box
    %   and sparse full-box share one specification source before sparse
    %   windowing is applied.
    nPar = expr.npar();
    degree = expr.Degree;
    if nPar == 1 && mod(degree, 2) == 1
        targetDeg = 2 .* order + 1;
        specs = {order, [0; 1]; order, [1; 0]};
    elseif nPar == 1
        targetDeg = 2 .* order;
        specs = {order, [0; 0]};
        if order > 0
            specs(end + 1, :) = {order - 1, [1; 1]};
        end
    else
        targetDeg = 2 .* order;
        masks = helper.combRows(repmat({0:1}, 1, nPar));
        specs = cell(size(masks, 1), 2);
        for k = 1:size(masks, 1)
            specs{k, 1} = order - masks(k, :);
            specs{k, 2} = [masks(k, :); masks(k, :)];
        end
    end
end
