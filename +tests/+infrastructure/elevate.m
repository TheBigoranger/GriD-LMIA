function output = elevate(input, degree, target)
    %ELEVATE Independent binomial incidence formula for each coefficient row.
    source = tests.infrastructure.labels(degree);
    labels = tests.infrastructure.labels(target);
    output = repmat({zeros(size(input{1}))}, size(input, 1), size(labels, 1));
    for j = 1:size(labels, 1)
        for k = 1:size(source, 1)
            delta = labels(j,:) - source(k,:);
            if any(delta < 0 | delta > target-degree), continue; end
            weight = 1;
            for dim = 1:numel(degree)
                weight = weight * nchoosek(degree(dim), source(k,dim)) ...
                    * nchoosek(target(dim)-degree(dim), delta(dim)) ...
                    / nchoosek(target(dim), labels(j,dim));
            end
            for row = 1:size(input, 1)
                output{row,j} = output{row,j} + weight*input{row,k};
            end
        end
    end
end
