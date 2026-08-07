function varargout = plot(obj, varargin)
    %PLOT Plot pdmat matrix entries over one or two grid dimensions.
    %
    %   Syntax:
    %     h = plot(A)
    %     h = plot(A, dims, Name, Value)
    %     h = plot(A, SamplesPerCell=n, RateVertex=k)
    %
    %   Arguments:
    %     A              - pdmat object to sample and plot.
    %     dims           - Optional one or two parameter dimensions.
    %     SamplesPerCell - Positive sample count per physical cell.
    %     RateVertex     - One-based rate row in combRows(RateBounds) order.
    %     Name, Value    - Additional MATLAB line or surface options.
    %
    %   Output:
    %     h - Line or surface graphics handles, one per matrix entry.
    %
    %   Example:
    %     A = pdmat({[0 1]}, @(rho) [rho, rho^2]);
    %     h = plot(A, SamplesPerCell=20);
    %     D = rhodiff(pdmat([0 1], {0, 1}, Degree=1, ...
    %         RateBounds=[-1 1]));
    %     plot(D, RateVertex=2);
    %
    %   A rate-row object defaults to RateVertex=1. Supplying RateVertex for
    %   ordinary data, or selecting beyond the stored vertex count, is an error.

    name = inputname(1);
    if isempty(name) || ~isvarname(name)
        name = "A";
    end

    [dims, args, spc, rateVertex] = parseArgs(obj, varargin);
    % Build legend labels once so the line and surface paths stay aligned.
    nEntry = prod(obj.MatrixSize);
    lbls = cell(1, nEntry);
    for k = 1:nEntry
        [r, c] = ind2sub(obj.MatrixSize, k);
        lbls{k} = sprintf("$%s_{%d,%d}$", name, r, c);
    end

    if numel(dims) == 1
        h = plot1(obj, dims, args, spc, rateVertex, lbls);
    else
        h = plot2(obj, dims, args, spc, rateVertex, lbls);
    end

    if nargout > 0
        varargout{1} = h;
    end
end

function [dims, args, spc, rateVertex] = parseArgs(obj, args)
    %PARSEARGS Select dimensions and remove package-owned plot options.
    if obj.npar() == 1
        dims = 1;
    else
        dims = [1 2];
    end

    if ~isempty(args) && isnumeric(args{1})
        dims = helper.chk(args{1}, "pdmat:InvalidPlotDimensions", ...
            "plot dimensions", ...
            "numeric", "real", "vector", "finite", "integer", "positive");
        dims = reshape(double(dims), 1, []);
        if isempty(dims) || numel(dims) > 2 || any(dims > obj.npar()) || ...
                numel(unique(dims)) ~= numel(dims)
            error("pdmat:InvalidPlotDimensions", ...
                "Plot dimensions must be one or two valid parameter indices.");
        end
        args = args(2:end);
    end

    spc = 15;
    hasRows = obj.NumRateRows ~= 0;
    rateVertex = 1;
    seenRate = false;
    k = 1;
    while k <= numel(args)
        if (ischar(args{k}) || (isstring(args{k}) && isscalar(args{k}))) && ...
                strcmpi(string(args{k}), "SamplesPerCell")
            if k == numel(args)
                error("pdmat:InvalidPlotOptions", ...
                    "SamplesPerCell requires a positive integer scalar value.");
            end
            spc = helper.chk(args{k + 1}, "pdmat:InvalidPlotOptions", ...
                "SamplesPerCell", ...
                "numeric", "real", "scalar", "finite", "integer", "positive");
            spc = double(spc);
            args(k:(k + 1)) = [];
        elseif (ischar(args{k}) || ...
                (isstring(args{k}) && isscalar(args{k}))) && ...
                strcmpi(string(args{k}), "RateVertex")
            if seenRate || k == numel(args)
                error("pdmat:InvalidRateVertex", ...
                    "RateVertex must be supplied once with a valid one-based index.");
            end
            rateVertex = helper.chk(args{k + 1}, ...
                "pdmat:InvalidRateVertex", ...
                "RateVertex", ...
                "numeric", "real", "scalar", "finite", "integer", "positive");
            rateVertex = double(rateVertex);
            seenRate = true;
            args(k:(k + 1)) = [];
        else
            k = k + 1;
        end
    end
    if seenRate && ~hasRows
        error("pdmat:InvalidRateVertex", ...
            "RateVertex is supported only for pdmat objects with explicit rate rows.");
    end
    if hasRows && rateVertex > obj.NumRateRows
        error("pdmat:InvalidRateVertex", ...
            "RateVertex exceeds the number of stored RateBounds vertices.");
    end
end

function x = denseVec(v, spc)
    %DENSEVEC Sample each grid interval without duplicating shared nodes.
    x = zeros(1, (numel(v) - 1) * spc + 1);
    pos = 1;
    for k = 1:(numel(v) - 1)
        pts = linspace(v(k), v(k + 1), spc + 1);
        if k > 1
            pts = pts(2:end);
        end
        idx = pos:(pos + numel(pts) - 1);
        x(idx) = pts;
        pos = pos + numel(pts);
    end
end

function h = plot1(obj, dim, args, spc, rateVertex, lbls)
    %PLOT1 Draw every matrix entry along one selected parameter dimension.
    x = denseVec(obj.GridInfo.Vectors{dim}, spc);
    base = obj.GridInfo.Bounds(:, 1).';
    nEntry = numel(lbls);
    vals = zeros(numel(x), nEntry);
    for k = 1:numel(x)
        pt = base;
        pt(dim) = x(k);
        vals(k, :) = reshape(plotValue(obj, pt, rateVertex), 1, []);
    end

    ax = gca;
    wasHold = ishold(ax);
    if ~wasHold
        cla(ax);
    end

    colors = lines(nEntry);
    h = gobjects(1, nEntry);
    hold(ax, "on");
    for k = 1:nEntry
        h(k) = builtin("plot", ax, x, vals(:, k), args{:}, Color=colors(k, :));
    end
    if ~wasHold
        hold(ax, "off");
    end

    legend(ax, h, lbls, Location="northeast", Interpreter="latex");
    xlabel(ax, sprintf("$\\rho_{%d}$", dim), Interpreter="latex");
    ylabel(ax, "value");
end

function h = plot2(obj, dims, args, spc, rateVertex, lbls)
    %PLOT2 Draw one surface per matrix entry over two selected dimensions.
    x = denseVec(obj.GridInfo.Vectors{dims(1)}, spc);
    y = denseVec(obj.GridInfo.Vectors{dims(2)}, spc);
    [X, Y] = meshgrid(x, y);
    vals = zeros([size(X), prod(obj.MatrixSize)]);
    base = obj.GridInfo.Bounds(:, 1).';

    for r = 1:numel(y)
        for c = 1:numel(x)
            pt = base;
            pt(dims(1)) = x(c);
            pt(dims(2)) = y(r);
            vals(r, c, :) = reshape( ...
                plotValue(obj, pt, rateVertex), 1, 1, []);
        end
    end

    hasAlpha = false;
    for k = 1:numel(args)
        if (ischar(args{k}) || (isstring(args{k}) && isscalar(args{k}))) && ...
                strcmpi(string(args{k}), "FaceAlpha")
            hasAlpha = true;
            break
        end
    end
    if ~hasAlpha
        args = [args, {"FaceAlpha", 0.5}];
    end

    ax = gca;
    wasHold = ishold(ax);
    if ~wasHold
        cla(ax);
    end

    nEntry = numel(lbls);
    h = gobjects(1, nEntry);
    colors = lines(nEntry);
    for k = 1:nEntry
        h(k) = surf(ax, X, Y, vals(:, :, k), args{:}, ...
            DisplayName=lbls{k}, FaceColor=colors(k, :));
        hold(ax, "on");
    end
    if ~wasHold
        hold(ax, "off");
    end

    legend(ax, h, lbls, Location="northeast", Interpreter="latex");
    xlabel(ax, sprintf("$\\rho_{%d}$", dims(1)), Interpreter="latex");
    ylabel(ax, sprintf("$\\rho_{%d}$", dims(2)), Interpreter="latex");
    zlabel(ax, "value");
end

function val = plotValue(obj, pt, rateVertex)
    %PLOTVALUE Select one stored rate row after exact Bernstein evaluation.
    val = obj.evaluate(pt);
    if iscell(val)
        val = val{rateVertex};
    end
end
