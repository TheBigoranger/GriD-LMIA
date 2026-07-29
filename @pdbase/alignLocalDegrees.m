function data = alignLocalDegrees(data, targetDegree, grid, validationMode)
    %ALIGNLOCALDEGREES Reuse one elevation plan per distinct source degree.

    if nargin < 4
        validationMode = "fast";
    end
    sourceDegrees = vertcat(data.Degree);
    lower = any(sourceDegrees < targetDegree, 2);
    plannedDegrees = unique(sourceDegrees(lower, :), "rows", "stable");
    plans = cell(size(plannedDegrees, 1), 1);
    for planIndex = 1:size(plannedDegrees, 1)
        plans{planIndex} = pdbase.elevationPlan( ...
            plannedDegrees(planIndex, :), targetDegree, numel(grid));
    end

    for dataIndex = 1:numel(data)
        plan = [];
        if any(data(dataIndex).Degree < targetDegree)
            planIndex = find(all(plannedDegrees == ...
                data(dataIndex).Degree, 2), 1);
            plan = plans{planIndex};
        end
        data(dataIndex).LocalValues = pdbase.elevLocalValues( ...
            data(dataIndex).LocalValues, data(dataIndex).Degree, ...
            targetDegree, grid, plan, validationMode);
    end
end
