function results = benchmark_continuity(outputFile, mapFunction)
    %BENCHMARK_CONTINUITY Measure construction stages without timing assertions.
    % Run in a fresh MATLAB process. The optional mapFunction identifies a
    % baseline's numeric axis-map builder; otherwise a disposable copy of the
    % current private plan is used without exposing a production API.
    % Example: tests.infrastructure.benchmark_continuity('results.mat')
    % Times columns: axis-plan preparation, pdvar construction, pdmat
    % classification, rhodiff construction, and direct LMI assembly.
    % The separate axis-plan microbenchmark also measures C0 plans, although
    % the unchanged all-C0 constructor does not need to build these plans.
    if nargin < 2
        sourceRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
        scratch = tempname;
        mkdir(scratch);
        copyfile(fullfile(sourceRoot,'@pdvar','private','splinePlan.m'), scratch);
        addpath(scratch);
        mapCleanup = onCleanup(@() removePlanCopy(scratch)); %#ok<NASGU>
        mapFunction = 'splinePlan';
    end
    cases = struct('Name', {}, 'Grid', {}, 'Degree', {}, 'Order', {});
    for count = [2 25 100]
        for degree = [3 5]
            for graded = [false true]
                widths = ones(1, count);
                if graded, widths = logspace(0, 6, count); end
                grid = -2 + 5 * [0 cumsum(widths)] / sum(widths);
                for order = [0 1 degree-1 Inf]
                    name = sprintf('K%d_d%d_q%g_g%d', count, degree, order, graded);
                    cases(end+1) = struct('Name', name, 'Grid', {{grid}}, ...
                        'Degree', degree, 'Order', order); %#ok<AGROW>
                end
            end
        end
    end
    cases(end+1) = struct('Name', 'tensor2', ...
        'Grid', {{linspace(-2,3,9), linspace(1,4,7)}}, ...
        'Degree', [3 2], 'Order', [2 1]);
    cases(end+1) = struct('Name', 'tensor3', ...
        'Grid', {{[-2 -1 0 3], [1 1.3 2 4], [-1 0 2]}}, ...
        'Degree', [3 2 2], 'Order', [0 1 Inf]);
    results = struct('Cases', [], 'Matlab', version, 'Repetitions', 5);
    warnState = warning('off', 'pdmat:DiscontinuousLocalValues');
    cleanup = onCleanup(@() warning(warnState)); %#ok<NASGU>
    for k = 1:numel(cases)
        cfg = cases(k);
        elapsed = zeros(6, 5);
        numeric = knownValues(cfg);
        for repetition = 1:6
            yalmip('clear');
            tic;
            plans = cell(1,numel(cfg.Degree));
            for axis = 1:numel(cfg.Degree)
                plans{axis} = feval(mapFunction, cfg.Grid{axis}, ...
                    cfg.Degree(axis), cfg.Order(axis));
            end
            elapsed(repetition,1) = toc;
            tic;
            P = pdvar(2, cfg.Grid, 'symmetric', ...
                Degree=cfg.Degree, Continuity=cfg.Order);
            elapsed(repetition,2) = toc;
            tic;
            known = pdmat(cfg.Grid, numeric, Degree=cfg.Degree); %#ok<NASGU>
            elapsed(repetition,3) = toc;
            tic;
            derivative = rhodiff(P, repmat([-1 1], numel(cfg.Degree), 1)); %#ok<NASGU>
            elapsed(repetition,4) = toc;
            tic;
            constraint = P >= eye(2); %#ok<NASGU>
            elapsed(repetition,5) = toc;
        end
        measured = elapsed(2:end,:);
        metrics = representationMetrics(P, cfg);
        memory = whos('plans');
        row = struct('Name', cfg.Name, 'Degree', cfg.Degree, ...
            'Order', cfg.Order, 'Times', measured, ...
            'Median', median(measured,1), 'Min', min(measured,[],1), ...
            'Max', max(measured,[],1), 'MapBytes', memory.bytes, ...
            'AffineNNZ', metrics.NNZ, 'MaxWeight', metrics.MaxWeight, ...
            'SeamError', metrics.SeamError, 'VariableCount', metrics.VariableCount);
        results.Cases = [results.Cases row];
        save(outputFile, 'results');
        fprintf('BENCH %d/%d %s median=[%s] nnz=%d maxweight=%.4g seam=%.3g\n', ...
            k,numel(cases),cfg.Name,num2str(row.Median,' %.6g'), ...
            row.AffineNNZ,row.MaxWeight,row.SeamError);
    end
end

function removePlanCopy(scratch)
    % This directory and single file were created by this invocation only.
    rmpath(scratch);
    delete(fullfile(scratch,'splinePlan.m'));
    rmdir(scratch);
end

function vals = knownValues(cfg)
    % Same globally affine known function in both trees, independent of their
    % decision coordinates. On graded grids, rounded Bernstein coefficients
    % can limit the inferred order; both trees receive exactly the same data.
    counts = cellfun(@numel,cfg.Grid)-1;
    labels = tests.infrastructure.labels(cfg.Degree);
    vals = helper.mkNest(counts, @oneCell);
    function coeffs = oneCell(subs)
        coeffs = cell(1,size(labels,1));
        for j = 1:size(labels,1)
            x = 0;
            for axis = 1:numel(cfg.Degree)
                g = cfg.Grid{axis};
                x = x + axis * (g(subs(axis)) + ...
                    labels(j,axis)/cfg.Degree(axis)*diff(g(subs(axis):subs(axis)+1)));
            end
            coeffs{j} = [x+2, 0.3*x; 0.3*x, 2*x+5];
        end
    end
end

function out = representationMetrics(P, cfg)
    cells = P.cells();
    nCoeff = prod(cfg.Degree+1);
    values = cell(size(cells,1),nCoeff);
    for c = 1:size(cells,1), values(c,:) = P.coeffs(cells(c,:)); end
    flat = reshape(values',1,[]);
    expression = horzcat(flat{:});
    basis = getbase(expression(:));
    out.NNZ = nnz(basis(:,2:end));
    out.MaxWeight = full(max(abs(basis),[],'all'));
    out.VariableCount = size(basis,2)-1;
    out.SeamError = 0;
    labels = tests.infrastructure.labels(cfg.Degree);
    for axis = 1:numel(cfg.Degree)
        q = min(cfg.Order(axis), cfg.Degree(axis));
        faces = labels(labels(:,axis)==0,:);
        for c = 1:size(cells,1)
            neighbor = cells(c,:); neighbor(axis) = neighbor(axis)+1;
            next = find(all(cells==neighbor,2),1);
            if isempty(next), continue; end
            h = diff(cfg.Grid{axis}(cells(c,axis):cells(c,axis)+2));
            for order = 0:q
                for f = 1:size(faces,1)
                    left = sparse(4,size(basis,2)); right = left;
                    magnitude = 0;
                    for offset = 0:order
                        ll = faces(f,:); rr = ll;
                        ll(axis) = cfg.Degree(axis)-order+offset;
                        rr(axis) = offset;
                        li = find(all(labels==ll,2),1);
                        ri = find(all(labels==rr,2),1);
                        w = (-1)^(order-offset)*nchoosek(order,offset);
                        a = w/h(1)^order*basis(4*((c-1)*nCoeff+li-1)+(1:4),:);
                        b = w/h(2)^order*basis(4*((next-1)*nCoeff+ri-1)+(1:4),:);
                        left = left+a; right = right+b;
                        magnitude = magnitude+norm(a,'fro')+norm(b,'fro');
                    end
                    out.SeamError = max(out.SeamError, ...
                        norm(left-right,'fro')/max(1,magnitude));
                end
            end
        end
    end
end
