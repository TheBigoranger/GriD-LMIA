function map = bernRestrict(degree, lo, hi)
    %BERNRESTRICT Restrict Bernstein controls to a normalized subinterval.
    % Validated internal callers supply 0 <= lo < hi <= 1. Each row maps
    % original controls to one control on [lo,hi], preserving both endpoints.
    map = eye(degree + 1);
    if hi < 1
        [map, ~] = splitMap(map, hi);
    end
    if lo > 0
        [~, map] = splitMap(map, lo / hi);
    end
end

function [left, right] = splitMap(map, t)
    %SPLITMAP De Casteljau subdivision applied to numeric control weights.
    degree = size(map, 1) - 1;
    left = zeros(size(map));
    right = zeros(size(map));
    left(1, :) = map(1, :);
    right(end, :) = map(end, :);
    for level = 1:degree
        map = (1 - t) * map(1:end-1, :) + t * map(2:end, :);
        left(level + 1, :) = map(1, :);
        right(end - level, :) = map(end, :);
    end
end
