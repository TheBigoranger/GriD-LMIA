function certificatePlan = mkGramCertificatePlan(specs, nPar, bandWidth, targetDegree)
    %MKGRAMCERTIFICATEPLAN Expand dense or tensor-window Gram maps once.

    plans = {};
    for k = 1:size(specs, 1)
        gramDegree = reshape(specs{k, 1}, 1, []);
        if any(gramDegree < 0)
            % Negative nominal degrees denote omitted order-zero multipliers.
            continue
        end
        weight = specs{k, 2};
        alphaPower = reshape(weight(1, :), 1, nPar);
        oneMinusAlphaPower = reshape(weight(2, :), 1, nPar);
        if isempty(bandWidth)
            plans{end + 1, 1} = mkGramPlan(gramDegree, ...
                alphaPower, oneMinusAlphaPower); %#ok<AGROW>
        else
            % Axis-aligned tensor windows are independent of flattened labels.
            windowSize = min(bandWidth, gramDegree + 1);
            localLabels = labelRows(windowSize - 1);
            starts = labelRows(gramDegree - windowSize + 1);
            for window = 1:size(starts, 1)
                basisLabels = localLabels + starts(window, :);
                plans{end + 1, 1} = mkGramPlan(gramDegree, ...
                    alphaPower, oneMinusAlphaPower, basisLabels); %#ok<AGROW>
            end
        end
    end

    targetCount = prod(targetDegree + 1);
    for k = 1:numel(plans)
        if ~isequal(plans{k}.TargetDegree, targetDegree) || ...
                plans{k}.TargetCount ~= targetCount
            error("pdlmi:InvalidGramPowers", ...
                "Every Gram block must map to the common target tensor degree.");
        end
    end
    certificatePlan.Blocks = plans;
    certificatePlan.BlockCount = numel(plans);
    certificatePlan.TargetDegree = targetDegree;
    certificatePlan.TargetCount = targetCount;
end

function rows = labelRows(maxLabel)
    %LABELROWS Enumerate one tensor box in repository coefficient order.
    ranges = arrayfun(@(degree) 0:degree, maxLabel, ...
        "UniformOutput", false);
    rows = helper.combRows(ranges);
end
