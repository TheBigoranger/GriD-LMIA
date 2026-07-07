function out = unOp(obj, fcn, sz)
    %UNOP Apply a unary operation to every dpvar coefficient.
    chkNoDeriv(obj, "dpvar:UnsupportedDerivativeRows");

    if nargin < 3 || isempty(sz)
        % Infer matrix size from one mapped coefficient, allowing trace/transpose.
        coeffs = internal.cellGet(obj.LocalValues, ones(1, obj.npar()));
        sample = mapCoeff(coeffs{1}, fcn);
        if isstruct(sample)
            sz = size(sample.Constant);
        else
            sz = size(sample);
        end
    end
    vals = internal.mapVals(obj.LocalValues, @(a) mapCoeff(a, fcn), ...
        obj.GridInfo.Vectors);

    out = dpvar(mkInit(obj.GridInfo.Vectors, sz, obj.Degree, vals, ...
        obj.ContainsDecision, obj.HasRateDependence, obj.RateBounds, "expression"));
end

function val = mapCoeff(val, fcn)
    if ~isstruct(val)
        val = fcn(val);
        return
    end

    % Rate-affine payloads keep rho_dot metadata outside LocalValues while
    % each stored matrix term undergoes the same structural transform.
    val.Constant = fcn(val.Constant);
    val.Rate = cellfun(fcn, val.Rate, UniformOutput=false);
end
