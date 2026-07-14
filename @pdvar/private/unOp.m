function out = unOp(obj, fcn, sz)
    %UNOP Apply a unary operation to every pdvar coefficient.
    %
    %   Syntax:
    %     out = unOp(obj, fcn, sz)
    %
    %   Example (via public algebra):
    %     P = pdvar(1, {[0 1]});
    %     Q = -P;

    if nargin < 3 || isempty(sz)
        % Infer matrix size from one mapped coefficient, allowing trace/transpose.
        coeffs = helper.cellGet(obj.LocalValues, ones(1, obj.npar()));
        sample = mapCoeff(coeffs{1}, fcn);
        if isstruct(sample)
            sz = size(sample.Constant);
        else
            sz = size(sample);
        end
    end
    vals = helper.mapVals(obj.LocalValues, @(a) mapCoeff(a, fcn), ...
        obj.GridInfo.Vectors);

    out = pdvar(mkInit(obj.GridInfo.Vectors, sz, obj.Degree, vals, ...
        obj.ContainsDecision, obj.HasRateDependence, obj.RateBounds, ...
        "expression", obj.IsContinuous));
end

function val = mapCoeff(val, fcn)
    %MAPCOEFF Apply FCN to one ordinary or rate-affine coefficient payload.
    %
    %   Syntax:
    %     val = mapCoeff(val, fcn)
    %
    %   Rate-affine payloads transform Constant and every Rate term but keep
    %   their rate metadata and row ordering unchanged.
    if ~isstruct(val)
        val = fcn(val);
        return
    end

    % Rate-affine payloads keep rho_dot metadata outside LocalValues while
    % each stored matrix term undergoes the same structural transform.
    val.Constant = fcn(val.Constant);
    val.Rate = cellfun(fcn, val.Rate, UniformOutput=false);
end
