function varargout = plot(obj, varargin)
    %PLOT Plot dpmat matrix entries over one or two grid dimensions.
    %
    %   Syntax:
    %     h = plot(A)
    %     h = plot(A, dims, Name, Value)
    %     h = plot(A, SamplesPerCell=n)
    %
    %   Example:
    %     A = dpmat({[0 1]}, @(rho) [rho, rho^2]);
    %     h = plot(A, SamplesPerCell=20);

    name = inputname(1);
    if isempty(name) || ~isvarname(name)
        name = "A";
    end

    [dims, args, spc] = parseArgs(obj, varargin);
    % Build legend labels once so the line and surface paths stay aligned.
    nEntry = prod(obj.MatrixSize);
    lbls = cell(1, nEntry);
    for k = 1:nEntry
        [r, c] = ind2sub(obj.MatrixSize, k);
        lbls{k} = sprintf("$%s_{%d,%d}$", name, r, c);
    end

    if numel(dims) == 1
        h = plot1(obj, dims, args, spc, lbls);
    else
        h = plot2(obj, dims, args, spc, lbls);
    end

    if nargout > 0
        varargout{1} = h;
    end
end

function [dims, args, spc] = parseArgs(obj, args)
    if obj.npar() == 1
        dims = 1;
    else
        dims = [1 2];
    end

    if ~isempty(args) && isnumeric(args{1})
        dims = helper.chk(args{1}, "dpmat:InvalidPlotDimensions", ...
            "Plot dimensions must be one or two valid parameter indices.", ...
            "numeric", "real", "vector", "finite", "integer", "positive");
        dims = reshape(double(dims), 1, []);
        if isempty(dims) || numel(dims) > 2 || any(dims > obj.npar()) || ...
                numel(unique(dims)) ~= numel(dims)
            error("dpmat:InvalidPlotDimensions", ...
                "Plot dimensions must be one or two valid parameter indices.");
        end
        args = args(2:end);
    end

    spc = 15;
    k = 1;
    while k <= numel(args)
        if (ischar(args{k}) || (isstring(args{k}) && isscalar(args{k}))) && ...
                strcmpi(string(args{k}), "SamplesPerCell")
            if k == numel(args)
                error("dpmat:InvalidPlotOptions", ...
                    "SamplesPerCell requires a positive integer scalar value.");
            end
            spc = helper.chk(args{k + 1}, "dpmat:InvalidPlotOptions", ...
                "SamplesPerCell must be a positive integer scalar.", ...
                "numeric", "real", "scalar", "finite", "integer", "positive");
            spc = double(spc);
            args(k:(k + 1)) = [];
        else
            k = k + 1;
        end
    end
end

function x = denseVec(v, spc)
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

function h = plot1(obj, dim, args, spc, lbls)
    x = denseVec(obj.GridInfo.Vectors{dim}, spc);
    base = obj.GridInfo.Bounds(:, 1).';
    nEntry = numel(lbls);
    vals = zeros(numel(x), nEntry);
    for k = 1:numel(x)
        pt = base;
        pt(dim) = x(k);
        vals(k, :) = reshape(obj.evaluate(pt), 1, []);
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

function h = plot2(obj, dims, args, spc, lbls)
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
            vals(r, c, :) = reshape(obj.evaluate(pt), 1, 1, []);
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
