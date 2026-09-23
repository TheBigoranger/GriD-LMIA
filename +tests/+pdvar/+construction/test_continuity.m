function tests = test_continuity
    % Direction-wise continuity contracts for pdvar construction.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    yalmip("clear");
end

function test_defaults_normalization_warning_and_invalid_inputs(testCase)
    grid = {[0 1 2], [10 20 30]};
    ordinary = pdvar(1, grid, Degree=[3 2]);
    single = pdvar(1, {[0 1], [10 20 30]}, ...
        Degree=[3 2], Continuity=[0 1]);
    degreeZero = pdvar(1, grid, Degree=[0 2], Continuity=[0 1]);

    testCase.verifyEqual(ordinary.Continuity, [0 0]);
    testCase.verifyTrue(ordinary.IsContinuous);
    testCase.verifyEqual(single.Continuity, [Inf 1]);
    testCase.verifyEqual(degreeZero.Continuity, [Inf 1]);
    testCase.verifyWarning(@() pdvar(1, grid, Degree=[3 2], Continuity=1), ...
        "pdvar:ScalarContinuityExpansion");
    testCase.verifyWarningFree(@() pdvar(1, [0 1 2], ...
        Degree=3, Continuity=1));

    bad = {[], -1, [0 -1], [0 1 2], [0.5 1], [NaN 0], "C1"};
    for k = 1:numel(bad)
        testCase.verifyError(@() pdvar(1, grid, Degree=[3 2], ...
            Continuity=bad{k}), "pdvar:InvalidContinuity");
    end
    testCase.verifyError(@() pdvar(1, grid, Degree=[3 2], ...
        Continuity=0, Continuity=1), "pdvar:DuplicateOption");
end

function test_twenty_five_cubic_decision_counts(testCase)
    % Twenty-five cubic cells expose the requested independent-control counts.
    grid = {0:25};
    requests = {0, 1, 2, Inf};
    expected = [76, 52, 28, 4];

    for k = 1:numel(requests)
        P = pdvar(1, grid, Degree=3, Continuity=requests{k});
        testCase.verifyEqual(P.Continuity, requests{k});
        variableCount = numel(objectVariables(P));
        testCase.verifyEqual(variableCount, expected(k));
    end
end

function test_nonuniform_seams_and_affine_basis_rank(testCase)
    grid = {[0 1 3]};
    requests = {0, 1, 2, Inf};
    expected = [7, 6, 5, 4];
    for k = 1:numel(requests)
        P = pdvar(1, grid, Degree=3, Continuity=requests{k});
        verifySeams(testCase, P, requests{k});
        [variableCount, affineRank] = scalarRepresentationRank(P);
        testCase.verifyEqual(variableCount, expected(k));
        testCase.verifyEqual(affineRank, expected(k));
    end
end

function test_anisotropic_mixed_orders_zero_degree_and_matrix_counts(testCase)
    grid = {[0 2 5], [-3 1 7]};
    full = pdvar(2, 3, grid, "full", ...
        Degree=[2 3], Continuity=[1 2]);
    symmetric = pdvar(2, grid, "symmetric", ...
        Degree=[2 3], Continuity=[1 2]);
    zeroAxis = pdvar(1, grid, Degree=[0 3], Continuity=[0 1]);

    testCase.verifyEqual(full.Continuity, [1 2]);
    testCase.verifyEqual(symmetric.Continuity, [1 2]);
    testCase.verifyEqual(zeroAxis.Continuity, [Inf 1]);
    testCase.verifyEqual(numel(objectVariables(full)), 4 * 5 * 6);
    testCase.verifyEqual(numel(objectVariables(symmetric)), 4 * 5 * 3);
    testCase.verifyEqual(numel(objectVariables(zeroAxis)), 6);
    verifySeams(testCase, full, [1 2]);
    verifySeams(testCase, symmetric, [1 2]);
    verifySeams(testCase, zeroAxis, [0 1]);
end

function verifySeams(testCase, obj, orders)
    % Compare each seam derivative with an independent finite-difference formula.
    degree = obj.Degree;
    grid = obj.GridInfo.Vectors;
    if isscalar(orders)
        orders = repmat(orders, 1, numel(degree));
    end
    orders(isinf(orders)) = degree(isinf(orders));
    cells = obj.cells();
    labels = tests.infrastructure.labels(degree);
    for dim = 1:numel(degree)
        for cellIndex = 1:size(cells, 1)
            subs = cells(cellIndex, :);
            if subs(dim) == obj.GridInfo.NumNodes(dim) - 1
                continue
            end
            next = subs;
            next(dim) = next(dim) + 1;
            left = obj.coeffs(subs);
            right = obj.coeffs(next);
            hLeft = diff(grid{dim}(subs(dim):subs(dim)+1));
            hRight = diff(grid{dim}(next(dim):next(dim)+1));
            tangential = labels(labels(:, dim) == 0, :);
            for order = 0:orders(dim)
                for face = 1:size(tangential, 1)
                    label = tangential(face, :);
                    [lhs, leftMagnitude] = finiteDifference(left, labels, ...
                        label, dim, degree(dim) - order, order);
                    [rhs, rightMagnitude] = finiteDifference(right, labels, ...
                        label, dim, 0, order);
                    residual = full(getbase(lhs / hLeft^order - rhs / hRight^order));
                    % Bound affine roundoff using absolute stencil operands
                    % and each physical width, not a fixed seam tolerance.
                    scale = leftMagnitude / hLeft^order + ...
                        rightMagnitude / hRight^order;
                    bound = 64 * (sum(degree) + order + 1) * eps * max(1, scale);
                    testCase.verifyLessThanOrEqual(norm(residual, 'fro'), bound);
                end
            end
        end
    end
end

function [out, magnitude] = finiteDifference(coeffs, labels, label, dim, start, order)
    out = 0;
    magnitude = 0;
    for offset = 0:order
        one = label;
        one(dim) = start + offset;
        index = find(all(labels == one, 2), 1);
        out = out + (-1)^(order-offset) * nchoosek(order, offset) * ...
            coeffs{index};
        magnitude = magnitude + nchoosek(order, offset) * ...
            norm(full(getbase(coeffs{index})), 'fro');
    end
end

function [nVariables, affineRank] = scalarRepresentationRank(obj)
    expressions = [];
    for subs = obj.cells()'
        coeffs = obj.coeffs(subs');
        expressions = [expressions; vertcat(coeffs{:})]; %#ok<AGROW>
    end
    nVariables = numel(getvariables(expressions));
    basis = full(getbase(expressions));
    affineRank = rank(basis(:, 2:end));
end

function variables = objectVariables(obj)
    variables = [];
    for subs = obj.cells()'
        coeffs = obj.coeffs(subs');
        for k = 1:numel(coeffs)
            variables = [variables getvariables(coeffs{k})]; %#ok<AGROW>
        end
    end
    variables = unique(variables);
end

function test_spline_basis_degrees_orders_grids_and_endpoints(testCase)
    grids = {[0 1 2 3], [-3 -2.75 0.5 4], [-2 5]};
    for degree = 0:5
        for order = [0:degree, degree+2, Inf]
            for gridIndex = 1:numel(grids)
                grid = grids{gridIndex};
                P = pdvar(1, grid, Degree=degree, Continuity=order);
                map = scalarMap(P);
                q = min(order, degree);
                count = degree + 1 + (numel(grid)-2) * (degree-q);
                testCase.verifySize(map, [(numel(grid)-1)*(degree+1), count]);
                testCase.verifyEqual(rank(map), count);
                testCase.verifyEqual(sum(map, 2), ones(size(map, 1), 1), ...
                    AbsTol=64*(degree+1)*eps);
                testCase.verifyGreaterThanOrEqual(min(map(:)), -64*(degree+1)*eps);
                for c = 1:numel(grid)-1
                    rows = (c-1)*(degree+1) + (1:degree+1);
                    window = (c-1)*(degree-q) + (1:degree+1);
                    outside = setdiff(1:count, window);
                    testCase.verifyEqual(map(rows, outside), zeros(degree+1, numel(outside)));
                    for t = [0, .173, .619, 1]
                        x = grid(c) + t*(grid(c+1)-grid(c));
                        expected = tests.infrastructure.spline_basis({grid}, degree, order, x);
                        bernstein = arrayfun(@(k) nchoosek(degree,k)* ...
                            t^k*(1-t)^(degree-k), 0:degree);
                        testCase.verifyEqual(bernstein*map(rows, :), expected, ...
                            AbsTol=128*(degree+1)*eps);
                    end
                end
                verifySeams(testCase, P, q);
            end
        end
    end
end

function test_small_spaces_equal_previous_free_control_parameterization(testCase)
    % The old coordinates fixed cell one and each later unconstrained tail.
    % Solve the defining seam system directly instead of copying its recurrence.
    grid = [-2 -1 1 4];
    for degree = 1:5
        for q = 0:degree
            P = pdvar(1, grid, Degree=degree, Continuity=q);
            actual = scalarMap(P);
            constraints = zeros(2*(q+1), 3*(degree+1));
            for seam = 1:2
                for order = 0:q
                    row = (seam-1)*(q+1)+order+1;
                    stencil = arrayfun(@(k) (-1)^(order-k)*nchoosek(order,k), 0:order);
                    lhs = (seam-1)*(degree+1) + (degree-order:degree)+1;
                    rhs = seam*(degree+1) + (0:order)+1;
                    constraints(row,lhs) = stencil / (grid(seam+1)-grid(seam))^order;
                    constraints(row,rhs) = -stencil / (grid(seam+2)-grid(seam+1))^order;
                end
            end
            free = [1:degree+1, degree+1+(q+2:degree+1), 2*(degree+1)+(q+2:degree+1)];
            dependent = setdiff(1:size(actual,1), free);
            old = zeros(size(actual));
            old(free,:) = eye(numel(free));
            old(dependent,:) = -constraints(:,dependent) \ constraints(:,free);
            testCase.verifyEqual(rank(old), numel(free));
            testCase.verifyEqual(rank([actual old]), numel(free));
            % Range agreement compares spaces, never differently defined controls.
            testCase.verifyLessThanOrEqual(norm(actual-old*(old\actual),'fro'), ...
                4096*eps*max(1,norm(old,'fro')*norm(actual,'fro')));
        end
    end
end

function test_c0_preserves_full_tensor_allocation_and_shared_identities(testCase)
    grid = {[0 .5 3], [-2 0 5]};
    degree = [2 3];
    P = pdvar(2, 3, grid, 'full', Degree=degree, Continuity=[0 0]);
    variables = objectVariables(P);
    labels = tests.infrastructure.labels(degree);
    controlsPerAxis = 2*degree+1;
    for subs = P.cells()'
        coefficients = P.coeffs(subs');
        for k = 1:size(labels,1)
            globalLabel = (subs'-1).*degree + labels(k,:);
            index = globalLabel(1)*controlsPerAxis(2)+globalLabel(2);
            expected = reshape(recover(variables(index*6+(1:6))), 2, 3);
            testCase.verifyEqual(getvariables(coefficients{k}), getvariables(expected));
            testCase.verifyEqual(full(getbase(coefficients{k}-expected)), zeros(6,1));
        end
    end
end

function test_tensor_basis_matrix_payloads_and_zero_infinite_axes(testCase)
    grids = {{[-2 -.5 3], [1 1.25 4]}, ...
        {[-2 -.5 3], [1 1.25 4], [0 2 5]}, ...
        {[-2 -.5 3], [1 1.25 4], [0 2 5]}};
    degrees = {[2 3], [2 3 1], [0 3 2]};
    orders = {[1 2], [1 Inf 0], [0 1 Inf]};
    for fixture = 1:numel(grids)
        grid = grids{fixture}; degree = degrees{fixture}; order = orders{fixture};
        for kind = ["scalar", "full", "symmetric"]
            if kind == "full"
                P = pdvar(2, 3, grid, 'full', Degree=degree, Continuity=order);
                payload = 6;
            elseif kind == "symmetric"
                P = pdvar(2, grid, 'symmetric', Degree=degree, Continuity=order);
                payload = 3;
            else
                P = pdvar(1, grid, Degree=degree, Continuity=order);
                payload = 1;
            end
            ids = objectVariables(P);
            assignments = sin((1:numel(ids))*.71) + (1:numel(ids))/13;
            assign(recover(ids), assignments);
            controls = reshape(assignments, payload, []);
            count = prod(degree+1 + (cellfun(@numel,grid)-2).*(degree-min(degree,order)));
            testCase.verifyEqual(numel(ids), payload*count);
            for subs = P.cells()'
                coefficients = P.coeffs(subs');
                labels = tests.infrastructure.labels(degree);
                for t = [.17 .73]
                    alpha = mod(t+(0:numel(degree)-1)*.21,1);
                    point = zeros(1,numel(degree));
                    for dim = 1:numel(degree)
                        point(dim) = grid{dim}(subs(dim)) + alpha(dim)* ...
                            (grid{dim}(subs(dim)+1)-grid{dim}(subs(dim)));
                    end
                    expected = controls * tests.infrastructure.spline_basis(grid,degree,order,point)';
                    if kind == "full"
                        expected = reshape(expected,2,3);
                    elseif kind == "symmetric"
                        expected = [expected(1) expected(2); expected(2) expected(3)];
                    end
                    actual = zeros(size(expected));
                    for k = 1:size(labels,1)
                        weight = 1;
                        for dim = 1:numel(degree)
                            j = labels(k,dim); d = degree(dim); a = alpha(dim);
                            weight = weight*nchoosek(d,j)*a^j*(1-a)^(d-j);
                        end
                        actual = actual + weight*value(coefficients{k});
                    end
                    testCase.verifyEqual(actual,expected,AbsTol=512*eps*max(1,norm(expected,'fro')));
                end
            end
            verifySeams(testCase,P,min(degree,order));
        end
    end
end

function map = scalarMap(obj)
    expressions = [];
    for subs = obj.cells()'
        coefficients = obj.coeffs(subs');
        expressions = [expressions; vertcat(coefficients{:})]; %#ok<AGROW>
    end
    basis = full(getbase(expressions));
    map = basis(:,2:end);
end

function test_long_graded_grids_keep_bounded_local_extraction(testCase)
    for count = [25 100]
        grid = [-3, -3+cumsum(logspace(0,6,count))];
        for degree = [3 5]
            for order = [degree-1 Inf]
                P = pdvar(1,grid,Degree=degree,Continuity=order);
                map = scalarMap(P);
                testCase.verifyTrue(all(isfinite(map(:))));
                tolerance = 128*(degree+1)*eps;
                testCase.verifyGreaterThanOrEqual(min(map(:)),-tolerance);
                testCase.verifyLessThanOrEqual(max(map(:)),1+tolerance);
                testCase.verifyEqual(sum(map,2),ones(size(map,1),1),AbsTol=tolerance);
                for c = [1 ceil(count/2) count]
                    rows = (c-1)*(degree+1)+(1:degree+1);
                    for t = [.13 .73]
                        point = grid(c)+t*(grid(c+1)-grid(c));
                        bernstein = arrayfun(@(k) nchoosek(degree,k)* ...
                            t^k*(1-t)^(degree-k),0:degree);
                        reference = tests.infrastructure.spline_basis({grid},degree,order,point);
                        testCase.verifyEqual(bernstein*map(rows,:),reference,AbsTol=tolerance);
                    end
                end
                verifySeams(testCase,P,min(degree,order));
            end
        end
    end
end
