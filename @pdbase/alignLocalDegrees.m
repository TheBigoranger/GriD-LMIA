function data = alignLocalDegrees(data, targetDegree, grid, validationMode)
    %ALIGNLOCALDEGREES Reuse one elevation plan per distinct source degree.

    if nargin < 4
        validationMode = "fast";
    end
    sourceDegrees = arrayfun(@(item) item.Degree, data);
    plannedDegrees = unique(sourceDegrees(sourceDegrees < targetDegree));
    plans = cell(size(plannedDegrees));
    for planIndex = 1:numel(plannedDegrees)
        plans{planIndex} = pdbase.elevationPlan( ...
            plannedDegrees(planIndex), targetDegree, numel(grid));
    end

    for dataIndex = 1:numel(data)
        plan = [];
        if data(dataIndex).Degree < targetDegree
            planIndex = find(plannedDegrees == ...
                data(dataIndex).Degree, 1);
            plan = plans{planIndex};
        end
        data(dataIndex).LocalValues = pdbase.elevLocalValues( ...
            data(dataIndex).LocalValues, data(dataIndex).Degree, ...
            targetDegree, grid, plan, validationMode);
    end
end
