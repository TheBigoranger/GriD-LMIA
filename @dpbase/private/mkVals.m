function vals = mkVals(nCell, nCoeff, sz)
    %MKVALS Allocate nested physical cells of zero payloads.

    vals = cell(1, nCell(1));
    for k = 1:nCell(1)
        if isscalar(nCell)
            % Each physical cell stores a flat coefficient cell in local-label
            % combination order, not a tensor-shaped coefficient array.
            vals{k} = zeroCoeff(nCoeff, sz);
        else
            % Nested cells model physical hypercubes:
            % LocalValues{i1}{i2}... rather than LocalValues{i1,i2,...}.
            vals{k} = mkVals(nCell(2:end), nCoeff, sz);
        end
    end
end

function coeffs = zeroCoeff(nCoeff, sz)
    % Allocate an ordinary numeric zero for each local Bernstein label.
    coeffs = cell(1, nCoeff);
    for k = 1:nCoeff
        coeffs{k} = zeros(sz);
    end
end
