function plan = splinePlan(grid, degree, order)
    %SPLINEPLAN Numeric cell-wise extraction from one axis of spline controls.
    % Inputs are validated constructor metadata. Extraction{e} maps the
    % selected controls to Bernstein coefficients, i.e. b = E * c. This is
    % the transpose of the basis-extraction convention N = C * B in Borden
    % et al., ICES report 10-08, Algorithm 1. No decisions enter this plan.
    nCell = numel(grid) - 1;
    if order >= degree || nCell == 1
        order = degree;
    end
    stride = degree - order;
    plan.NumControls = degree + 1 + (nCell - 1) * stride;
    plan.ControlIndices = cell(1, nCell);
    plan.Extraction = cell(1, nCell);
    for e = 1:nCell
        % Interior knot multiplicity degree-order advances each window;
        % neighboring cells overlap in order+1 independent spline controls.
        plan.ControlIndices{e} = (e - 1) * stride + (1:degree+1);
        plan.Extraction{e} = speye(degree + 1);
    end
    if degree == 0 || nCell == 1 || order == 0
        return
    end

    if order == degree
        for e = 1:nCell
            % Restrict the original full-domain polynomial independently to
            % every physical cell. Propagating from earlier small cells can
            % amplify roundoff by powers of successive physical width ratios.
            span = grid(end) - grid(1);
            lo = (grid(e) - grid(1)) / span;
            hi = (grid(e + 1) - grid(1)) / span;
            plan.Extraction{e} = sparse(helper.bernRestrict(degree, lo, hi));
        end
        return
    end

    % Clamped knots and interior multiplicity degree-order define precisely
    % the requested spline space. Element knot insertion carries only two
    % small extraction matrices, not a knot-by-global-control matrix.
    knots = [repmat(grid(1), 1, degree + 1), ...
        repelem(grid(2:end-1), stride), repmat(grid(end), 1, degree + 1)];
    a = degree + 1;
    b = a + 1;
    extraction = eye(degree + 1);
    for e = 1:nCell
        first = b;
        while b < numel(knots) && knots(b + 1) == knots(b)
            b = b + 1;
        end
        multiplicity = b - first + 1;
        next = eye(degree + 1);
        if multiplicity < degree
            numerator = knots(b) - knots(a);
            alphas = numerator ./ ...
                (knots(a + (multiplicity+1:degree)) - knots(a));
            insertions = degree - multiplicity;
            for j = 1:insertions
                saved = insertions - j + 1;
                s = multiplicity + j;
                for k = degree+1:-1:s+1
                    alpha = alphas(k - s);
                    extraction(:, k) = alpha * extraction(:, k) + ...
                        (1 - alpha) * extraction(:, k - 1);
                end
                if e < nCell
                    next(saved:saved+j, saved) = ...
                        extraction(degree-j+1:degree+1, degree+1);
                end
            end
        end
        plan.Extraction{e} = sparse(extraction');
        a = b;
        b = b + 1;
        extraction = next;
    end
end
