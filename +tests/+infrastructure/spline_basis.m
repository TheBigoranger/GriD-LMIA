function weights = spline_basis(grid, degree, order, point)
    %SPLINE_BASIS Independent Cox-de Boor reference, last tensor axis fastest.
    % This evaluates the defining knot basis, never a production extraction
    % matrix. Orders at degree describe one polynomial on the original domain.
    weights = 1;
    for dim = 1:numel(degree)
        d = degree(dim);
        nodes = grid{dim};
        q = min(order(dim), d);
        knots = [repmat(nodes(1), 1, d + 1), ...
            repelem(nodes(2:end-1), d - q), ...
            repmat(nodes(end), 1, d + 1)];
        x = point(dim);
        count = numel(knots) - d - 1;
        if x == nodes(end)
            basis = [zeros(1, count - 1), 1];
        else
            basis = double(knots(1:end-1) <= x & x < knots(2:end));
            for level = 1:d
                next = zeros(1, numel(knots) - level - 1);
                for k = 1:numel(next)
                    left = knots(k + level) - knots(k);
                    right = knots(k + level + 1) - knots(k + 1);
                    if left > 0
                        next(k) = (x - knots(k)) / left * basis(k);
                    end
                    if right > 0
                        next(k) = next(k) + ...
                            (knots(k + level + 1) - x) / right * basis(k + 1);
                    end
                end
                basis = next;
            end
        end
        weights = kron(weights, basis);
    end
end
