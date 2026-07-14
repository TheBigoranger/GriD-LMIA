function cons = buildFullBoxPreorderConstraints(expr, relation, order)
    %BUILDFULLBOXPREORDERCONSTRAINTS Assemble certificates per cell and row.
    %
    %   The residual is elevated only to the certificate's matching degree.
    %   For a '<=' relation its coefficients are negated before matching, so
    %   localCertificate always represents a positive-semidefinite target.
    %   Constraint order is PSD blocks first, then exact Bernstein identities.
    %   Each physical cell is represented in forward normalized coordinates
    %   alpha=(rho-lo)/(hi-lo); no physical interval width enters this assembly.

    nPar = numel(expr.GridInfo.Vectors);
    degree = expr.Degree;
    if nPar == 1 && mod(degree, 2) == 1
        targetDegree = 2 * order + 1;
    else
        targetDegree = 2 * order;
    end
    vals = expr.elevVals(targetDegree - degree);
    cells = expr.cells();
    cons = {};

    for c = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(c, :));
        for row = 1:size(coeffs, 1)
            % A multirow leaf comes from rate-vertex expansion. Creating the
            % certificate inside both loops prevents Gram sharing across rate
            % vertices or physical cells.
            target = coeffs(row, :);
            for k = 1:numel(target)
                mat = target{k};
                if size(mat, 1) ~= size(mat, 2)
                    error("pdlmi:InvalidMatrixSize", ...
                        "DP-LMI constraints require square coefficient matrices.");
                end
                if isa(mat, "sdpvar")
                    symmetric = ishermitian(mat);
                else
                    symmetric = norm(mat - mat', inf) <= 1e-10;
                end
                if ~symmetric
                    error("pdlmi:NonSymmetricExpression", ...
                        "DP-LMI constraints require symmetric or Hermitian coefficient matrices.");
                end
                if relation == "<="
                    target{k} = -mat;
                end
            end
            [psdCons, represented] = localCertificate(expr.MatrixSize(1), ...
                nPar, degree, order);
            cons = [cons; psdCons]; %#ok<AGROW>
            % Coefficient identities are exact; strictness belongs in Residual.
            for k = 1:numel(target)
                cons{end + 1, 1} = represented{k} == target{k}; %#ok<AGROW>
            end
        end
    end
end

function [cons, coeffs] = localCertificate(n, nPar, degree, order)
    % Build the interval form or every multiplier in the box preordering.
    % specs stores the tensor Gram degree and the [alpha, 1-alpha] exponents.
    if nPar == 1
        if mod(degree, 2) == 0
            specs = {order, [0, 0]};
            if order > 0
                specs(end + 1, :) = {order - 1, [1, 1]};
            end
        else
            % Preserve physical block order: lower/left (1-alpha) first,
            % then upper/right alpha, while bernGramCoeffs arguments stay [a,b].
            specs = {order, [0, 1]; order, [1, 0]};
        end
    else
        % combRows fixes the subset order used elsewhere for tensor labels.
        % The all-zero mask is the unweighted block; every other mask is one
        % product of the selected box generators alpha_s(1-alpha_s).
        masks = helper.combRows(repmat({0:1}, 1, nPar));
        specs = cell(size(masks, 1), 2);
        for k = 1:size(masks, 1)
            specs{k, 1} = order - masks(k, :);
            specs{k, 2} = [masks(k, :)', masks(k, :)'];
        end
    end

    cons = {};
    coeffs = {};
    for k = 1:size(specs, 1)
        gramDegree = specs{k, 1};
        if any(gramDegree < 0)
            % This occurs only for zero order with a nonempty subset weight;
            % its nominal basis is empty and contributes no PSD block.
            continue
        end
        dim = n * prod(gramDegree + 1);
        gram = sdpvar(dim, dim, 'symmetric');
        cons{end + 1, 1} = gram >= 0; %#ok<AGROW>
        weight = specs{k, 2};
        if nPar == 1
            term = bernGramCoeffs(gram, gramDegree, ...
                weight(1), weight(2));
        else
            term = bernGramCoeffs(gram, gramDegree, ...
                weight(:, 1)', weight(:, 2)');
        end
        if isempty(coeffs)
            coeffs = term;
        else
            for j = 1:numel(coeffs)
                coeffs{j} = coeffs{j} + term{j};
            end
        end
    end
end
