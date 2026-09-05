function rows = labels(degree)
    %LABELS Independent mixed-radix labels; last axis varies fastest.
    degree = reshape(degree, 1, []);
    rows = zeros(prod(degree + 1), numel(degree));
    for k = 0:size(rows, 1)-1
        remainder = k;
        for dim = numel(degree):-1:1
            rows(k+1, dim) = mod(remainder, degree(dim)+1);
            remainder = floor(remainder / (degree(dim)+1));
        end
    end
end
