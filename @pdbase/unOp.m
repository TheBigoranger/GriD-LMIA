function out = unOp(obj, fcn, sz)
    %UNOP Map a unary operation over every stored coefficient payload.
    %
    %   Every physical-cell leaf is traversed in place. Rate-vertex tables
    %   retain all rows and columns, while legacy affine payloads transform
    %   both their Constant and Rate matrix terms.

    if obj.SourceSummary == "function"
        prefix = string(class(obj));
        error(prefix + ":FunctionOnlyAlgebra", ...
            "Function-backed %s objects need explicit Bernstein coefficient evidence for this operation.", ...
            prefix);
    end

    vals = pdbase.mapVals(obj.LocalValues, ...
        @(val) mapCoeff(val, fcn), obj.GridInfo.Vectors);
    if nargin < 3 || isempty(sz)
        % Size inference inspects one mapped value only; reconstruction still
        % receives the complete nested coefficient and rate-row storage.
        leaf = helper.cellGet(vals, ones(1, obj.npar()));
        sample = leaf{1};
        if isstruct(sample)
            sample = sample.Constant;
        end
        sz = size(sample);
    end

    out = mkUnOp(obj, vals, sz);
end

function val = mapCoeff(val, fcn)
    %MAPCOEFF Transform one ordinary or legacy rate-affine payload.
    if ~isstruct(val)
        val = fcn(val);
        return
    end

    val.Constant = fcn(val.Constant);
    val.Rate = cellfun(fcn, val.Rate, UniformOutput=false);
end
