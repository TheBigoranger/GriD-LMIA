function out = bernProd(obj, lhs, lhsDeg, rhs, rhsDeg)
    %BERNPROD Cell-local Bernstein coefficient product.
    %
    %   Syntax:
    %     out = bernProd(obj, lhs, lhsDeg, rhs, rhsDeg)
    %
    %   Arguments:
    %     lhs, rhs      - Flat coefficient rows for one physical cell.
    %     lhsDeg, rhsDeg - Scalar Bernstein degrees of the operands.
    %
    %   Output:
    %     out - Product coefficients at degree lhsDeg + rhsDeg.
    %
    %   Example (through public pdmat multiplication):
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     B = pdmat({[0 1]}, {3, 4}, Degree=1);
    %     C = A * B;

    %  sanity check inputs
    nPar = obj.npar();
    sanChk(lhsDeg, rhsDeg, lhs, rhs, nPar);

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

function sanChk(lhsDeg, rhsDeg, lhs, rhs, nPar)
    %SANCHK Validate both degrees and their flat tensor coefficient counts.
    lhsDeg = double(helper.chk(lhsDeg, "pdbase:InvalidDegree", ...
        "lhsDeg must be a nonnegative integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
    rhsDeg = double(helper.chk(rhsDeg, "pdbase:InvalidDegree", ...
        "rhsDeg must be a nonnegative integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "nonnegative"));

    lhsN = (lhsDeg + 1) ^ nPar;
    rhsN = (rhsDeg + 1) ^ nPar;
    helper.chk(lhs, "pdbase:InvalidCoefficientCell", ...
        "Coefficient cell counts must match operand degrees and parameter dimension.", ...
        "cell", "Numel", lhsN);
    helper.chk(rhs, "pdbase:InvalidCoefficientCell", ...
        "Coefficient cell counts must match operand degrees and parameter dimension.", ...
        "cell", "Numel", rhsN);
end
