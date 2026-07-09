function out = bernElev(obj, coeffs, fromDeg, toDeg)
    %BERNELEV Degree-elevate one cell's flat Bernstein coefficients.

    fromDeg = double(helper.chk(fromDeg, "dpbase:InvalidDegree", ...
        "fromDeg must be a nonnegative integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
    toDeg = double(helper.chk(toDeg, "dpbase:InvalidDegree", ...
        "toDeg must be a nonnegative integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
    if toDeg < fromDeg
        error("dpbase:InvalidDegreeElevation", ...
            "Cannot degree-elevate from degree %d to lower degree %d.", fromDeg, toDeg);
    end

    nPar = obj.npar();
    expected = (fromDeg + 1) ^ nPar;
    helper.chk(coeffs, "dpbase:InvalidCoefficientCell", ...
        "Coefficient cell count must match the source degree and parameter dimension.", ...
        "cell", "Numel", expected);
    if toDeg == fromDeg
        out = coeffs;
        return
    end

    oldLbls = helper.combRows(repmat({0:fromDeg}, 1, nPar));
    newLbls = helper.combRows(repmat({0:toDeg}, 1, nPar));
    out = cell(1, size(newLbls, 1));
    % gap is the extra Bernstein degree supplied by partition-of-unity factors.
    gap = toDeg - fromDeg;

    for outIdx = 1:size(newLbls, 1)
        outLbl = newLbls(outIdx, :);
        acc = [];
        for inIdx = 1:size(oldLbls, 1)
            inLbl = oldLbls(inIdx, :);
            if all(outLbl >= inLbl) && all((outLbl - inLbl) <= gap)
                % Tensor Bernstein degree elevation scales independently along
                % each parameter axis before accumulating into flat order.
                scale = 1;
                for k = 1:nPar
                    scale = scale ...
                        * nchoosek(fromDeg, inLbl(k)) ...
                        * nchoosek(gap, outLbl(k) - inLbl(k)) ...
                        / nchoosek(toDeg, outLbl(k));
                end
                term = coeffs{inIdx} .* scale;
                if isempty(acc)
                    acc = term;
                else
                    acc = acc + term;
                end
            end
        end
        out{outIdx} = acc;
    end
end
