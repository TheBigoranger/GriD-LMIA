function [tf, continuity] = chkCont(vals, nCell, degree, grids, maxOrders)
    %CHKCONT Verify and classify direction-wise continuity across cell faces.
    %
    %   Syntax:
    %     tf = helper.chkCont(vals, nCell, degree)
    %     [tf, continuity] = helper.chkCont(vals, nCell, degree, grids)
    %     [tf, continuity] = helper.chkCont(..., grids, maxOrders)
    %
    %   Arguments:
    %     vals      - Nested coefficient tree, including every active row.
    %     nCell     - 1-by-ell physical-cell count.
    %     degree    - 1-by-ell local Bernstein degree.
    %     grids     - Optional physical grid vectors used to scale derivatives.
    %     maxOrders - Optional scalar or ell-vector verification caps.
    %
    %   Outputs:
    %     tf         - True when every requested seam order matches.
    %     continuity - Highest proved order per direction, with -1 for a C0
    %                  failure and Inf after all orders through Degree pass.
    %
    %   Example:
    %     [tf, c] = helper.chkCont(vals, [2 1], [2 1], ...
    %         {[0 1 3], [0 2]}, [1 0]);
    %
    %   Existing three-input, one-output calls perform the historical C0
    %   check. Classification compares physical derivatives through the
    %   requested order on complete tensor faces, matrix entries, and rows.
    %   Forward differences are divided by the physical cell width to the
    %   requested power; the common Bernstein derivative factor cancels
    %   across each same-degree interface. Inf is returned only after every
    %   condition through the axis degree has passed.

    nPar = numel(nCell);
    nCell = reshape(nCell, 1, []);
    degree = reshape(degree, 1, []);
    if nargin < 4 || isempty(grids)
        grids = arrayfun(@(n) 0:n, nCell, "UniformOutput", false);
    end
    if nargin < 5 || isempty(maxOrders)
        if nargout < 2 && nargin == 3
            maxOrders = zeros(1, nPar);
        else
            maxOrders = degree;
        end
    elseif isscalar(maxOrders)
        maxOrders = repmat(maxOrders, 1, nPar);
    else
        maxOrders = reshape(maxOrders, 1, []);
    end

    if numel(degree) ~= nPar || numel(grids) ~= nPar || ...
            numel(maxOrders) ~= nPar
        error("helper:InvalidContinuityInput", ...
            "Cell counts, degrees, grids, and maximum orders must have one entry per parameter.");
    end

    cells = helper.combRows(arrayfun(@(n) 1:n, nCell, ...
        "UniformOutput", false));
    labels = helper.combRows(arrayfun(@(d) 0:d, degree, ...
        "UniformOutput", false));
    strides = fliplr(cumprod([1, fliplr(degree(2:end) + 1)]));
    continuity = inf(1, nPar);
    tf = true;
    for dim = 1:nPar
        if nCell(dim) == 1
            continue
        end
        limit = min(degree(dim), maxOrders(dim));
        continuity(dim) = -1;
        % A face's tangential labels and axis stride do not depend on its
        % physical cell, rate row, or matrix payload. Prepare them once.
        tangential = labels(labels(:, dim) == 0, :);
        faceStarts = 1 + tangential * strides';
        widths = diff(grids{dim});
        for order = 0:limit
            offsets = 0:order;
            weights = (-1).^(order - offsets) .* ...
                arrayfun(@(k) nchoosek(order, k), offsets);
            leftIndices = faceStarts + (degree(dim) - order + offsets) * strides(dim);
            rightIndices = faceStarts + offsets * strides(dim);
            % Physical derivative scaling is separate from the shared
            % finite-difference stencil, and must survive nonuniform grids.
            if ~orderMatches(dim, leftIndices, rightIndices, weights, widths.^order)
                tf = false;
                break
            end
            continuity(dim) = order;
        end
        if continuity(dim) == degree(dim)
            continuity(dim) = inf;
        elseif continuity(dim) < limit
            tf = false;
        end
    end

    function matches = orderMatches(dim, leftIndices, rightIndices, weights, widthPowers)
        matches = true;
        step = zeros(1, nPar);
        step(dim) = 1;
        for cellIdx = 1:size(cells, 1)
            subs = cells(cellIdx, :);
            if subs(dim) == nCell(dim)
                continue
            end
            lhs = helper.cellGet(vals, subs);
            rhs = helper.cellGet(vals, subs + step);
            for row = 1:size(lhs, 1)
                for faceIdx = 1:size(leftIndices, 1)
                    leftDiff = faceDiff(lhs, leftIndices(faceIdx, :), weights, ...
                        widthPowers(subs(dim)), row);
                    rightDiff = faceDiff(rhs, rightIndices(faceIdx, :), weights, ...
                        widthPowers(subs(dim) + 1), row);
                    if ~sameMat(leftDiff, rightDiff)
                        matches = false;
                        return
                    end
                end
            end
        end
    end

    function out = faceDiff(leaf, indices, weights, widthPower, row)
        out = 0;
        % Retain accumulation order and exact symbolic comparison semantics.
        for k = 1:numel(weights)
            out = out + weights(k) * leaf{row, indices(k)};
        end
        out = out ./ widthPower;
    end
end

function tf = sameMat(lhs, rhs)
    %SAMEMAT Compare numeric faces tolerantly and affine faces exactly.
    if isa(lhs, "sdpvar") || isa(rhs, "sdpvar")
        difference = lhs - rhs;
        if isa(difference, "sdpvar")
            % Comparing affine bases proves identity without assigning or
            % numerically sampling the underlying YALMIP decisions.
            tf = all(full(getbase(difference)) == 0, "all");
        else
            tf = isnumeric(difference) && all(difference == 0, "all");
        end
        return
    end
    difference = lhs - rhs;
    tol = 1e-9 * max([1, norm(lhs, 'fro'), norm(rhs, 'fro')]);
    tf = norm(difference, 'fro') <= tol;
end
