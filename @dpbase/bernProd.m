function out = bernProd(obj, lhs, lhsDeg, rhs, rhsDeg)
    %BERNPROD Cell-local Bernstein coefficient product.

    lhsDeg = double(helper.chk(lhsDeg, "dpbase:InvalidDegree", ...
        "lhsDeg must be a nonnegative integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
    rhsDeg = double(helper.chk(rhsDeg, "dpbase:InvalidDegree", ...
        "rhsDeg must be a nonnegative integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
    nPar = obj.npar();
    lhsN = (lhsDeg + 1) ^ nPar;
    rhsN = (rhsDeg + 1) ^ nPar;
    helper.chk(lhs, "dpbase:InvalidCoefficientCell", ...
        "Coefficient cell counts must match operand degrees and parameter dimension.", ...
        "cell", "Numel", lhsN);
    helper.chk(rhs, "dpbase:InvalidCoefficientCell", ...
        "Coefficient cell counts must match operand degrees and parameter dimension.", ...
        "cell", "Numel", rhsN);

    outDeg = lhsDeg + rhsDeg;
    lhsLbls = helper.combRows(repmat({0:lhsDeg}, 1, nPar));
    outLbls = helper.combRows(repmat({0:outDeg}, 1, nPar));
    rhsMult = (rhsDeg + 1) .^ (nPar - 1:-1:0);
    out = cell(1, size(outLbls, 1));

    for outIdx = 1:size(outLbls, 1)
        outLbl = outLbls(outIdx, :);
        acc = [];

        for lhsIdx = 1:size(lhsLbls, 1)
            lhsLbl = lhsLbls(lhsIdx, :);
            rhsLbl = outLbl - lhsLbl;

            if all(rhsLbl >= 0) && all(rhsLbl <= rhsDeg)
                rhsIdx = sum(rhsLbl .* rhsMult) + 1;
                % Product coefficients use binomial-normalized convolution; the
                % labels add within one physical cell, never across neighbors.
                scale = 1;

                for k = 1:nPar
                    scale = scale ...
                        * nchoosek(lhsDeg, lhsLbl(k)) ...
                        * nchoosek(rhsDeg, rhsLbl(k)) ...
                        / nchoosek(outDeg, outLbl(k));
                end

                term = (lhs{lhsIdx} * rhs{rhsIdx}) .* scale;

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
