function val = evaluate(obj, pt)
    %EVALUATE Evaluate pdmat data at one parameter point.
    %
    %   Syntax:
    %     val = evaluate(obj, pt)
    %     val = obj.evaluate(pt)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 3}, Degree=1);
    %     val = A.evaluate(0.25);

    pt = helper.chk(pt, "pdmat:InvalidPoint", ...
        "Evaluation point must be a finite real vector with one entry per parameter.", ...
        "numeric", "real", "vector", "finite", "Numel", obj.npar());
    pt = reshape(double(pt), 1, []);
    bounds = obj.GridInfo.Bounds;
    if any(pt < bounds(:, 1).') || any(pt > bounds(:, 2).')
        error("pdmat:PointOutOfBounds", ...
            "Evaluation point must lie inside the pdmat grid bounds.");
    end

    if ~isempty(obj.FunctionHandle)
        val = evalHandle(obj, pt);
        return
    end

    [subs, alpha] = localPoint(obj, pt);
    coeffs = obj.coeffs(subs);
    lbls = obj.lbls();
    val = zeros(obj.MatrixSize);
    % Keep the Bernstein weight formula at the evaluation site to avoid a
    % one-use helper chain around local coefficient reconstruction.
    for k = 1:numel(coeffs)
        w = 1;
        for p = 1:numel(alpha)
            j = lbls(k, p);
            w = w * nchoosek(obj.Degree, j) * ...
                (1 - alpha(p))^(obj.Degree - j) * alpha(p)^j;
        end
        val = val + coeffs{k} .* w;
    end
end

function val = evalHandle(obj, pt)
    args = num2cell(pt);
    try
        raw = obj.FunctionHandle(args{:});
    catch err
        error("pdmat:InvalidFunctionValue", ...
            "Function handle failed during evaluation: %s", err.message);
    end

    got = scanMats({raw}, "pdmat:InvalidFunctionValue", ...
        "Each pdmat payload must be a nonempty finite real numeric matrix.");
    if ~isequal(got, obj.MatrixSize)
        error("pdmat:InvalidFunctionValue", ...
            "Function handle must return the pdmat matrix size during evaluation.");
    end
    val = raw;
end

function [subs, alpha] = localPoint(obj, pt)
    nPar = obj.npar();
    subs = zeros(1, nPar);
    alpha = zeros(1, nPar);
    for p = 1:nPar
        v = obj.GridInfo.Vectors{p};
        x = pt(p);
        if x == v(end)
            subs(p) = numel(v) - 1;
        else
            subs(p) = find(v <= x, 1, "last");
        end

        lo = v(subs(p));
        hi = v(subs(p) + 1);
        % alpha=(x-lo)/(hi-lo) keeps label 0 lower and label m upper.
        alpha(p) = (x - lo) / (hi - lo);
    end
end
