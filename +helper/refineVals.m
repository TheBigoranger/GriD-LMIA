function vals = refineVals(info, obj)
    %REFINEVALS Re-express ordinary coefficients on a common refinement.
    % The caller validates matching bounds, ordinary rows and coefficient
    % evidence. Every target interval lies in one original physical cell.
    degree = obj.Degree;
    nPar = numel(degree);
    nCoeff = prod(degree + 1);
    nCell = info.NumNodes - 1;
    source = cell(1, nPar);
    maps = cell(1, nPar);
    order = cell(1, nPar);
    inverse = cell(1, nPar);
    labels = helper.combRows(arrayfun(@(d) 0:d, degree, ...
        UniformOutput=false));
    for dim = 1:nPar
        original = obj.GridInfo.Vectors{dim};
        target = info.Vectors{dim};
        source{dim} = zeros(1, nCell(dim));
        maps{dim} = cell(1, nCell(dim));
        for cellIdx = 1:nCell(dim)
            % Lower endpoints belong to the cell on their right. Using its
            % own coefficients also preserves the left limit at its upper face.
            src = find(original <= target(cellIdx), 1, 'last');
            source{dim}(cellIdx) = src;
            if degree(dim) == 0 || ...
                    isequal(target(cellIdx:cellIdx+1), original(src:src+1))
                continue
            end
            width = original(src + 1) - original(src);
            lo = (target(cellIdx) - original(src)) / width;
            hi = (target(cellIdx + 1) - original(src)) / width;
            maps{dim}{cellIdx} = helper.bernRestrict(degree(dim), lo, hi);
        end
        % Make this axis the slowest varying index. Each column then holds
        % all other tensor fibers, so one small contraction transforms them all.
        axes = [dim, 1:dim-1, dim+1:nPar];
        [~, order{dim}] = sortrows(labels, axes);
        inverse{dim}(order{dim}) = 1:nCoeff;
    end
    vals = helper.mkNest(nCell, @refineCell);

    function coeffs = refineCell(subs)
        src = zeros(1, nPar);
        changed = false(1, nPar);
        for axis = 1:nPar
            src(axis) = source{axis}(subs(axis));
            changed(axis) = ~isempty(maps{axis}{subs(axis)});
        end
        coeffs = helper.cellGet(obj.LocalValues, src);
        if ~any(changed)
            return
        end
        sz = obj.MatrixSize;
        entries = prod(sz);
        packed = reshape(horzcat(coeffs{:}), entries, nCoeff);
        for axis = find(changed)
            map = maps{axis}{subs(axis)};
            if isa(packed, 'single')
                map = single(map);
            end
            fibers = reshape(packed(:, order{axis}), [], degree(axis) + 1);
            packed = reshape(fibers * map', entries, nCoeff);
            packed = packed(:, inverse{axis});
        end
        for k = 1:nCoeff
            coeffs{k} = reshape(packed(:, k), sz);
        end
    end
end
