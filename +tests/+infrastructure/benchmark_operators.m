function results = benchmark_operators(outputFile, repetitions, selected)
    %BENCHMARK_OPERATORS Reproducible public-operation timings for paired runs.
    % Run in a fresh MATLAB process; fixture creation and validation are untimed.
    % tests.infrastructure.benchmark_operators('operator-times.json',7)
    if nargin < 2, repetitions = 7; end
    if nargin < 3, selected = []; end
    maxNumCompThreads(1);
    rng(20260922,'twister');
    manifest = jsondecode(fileread(fullfile(fileparts(mfilename('fullpath')), ...
        'operator_benchmark_manifest.json')));
    cases = manifest.Cases;
    if ~isempty(selected), cases = cases(ismember(string({cases.Name}),string(selected))); end
    results = struct('Matlab',version,'Computer',computer,'Threads',1, ...
        'Seed',20260922,'Warmups',3,'Repetitions',repetitions,'Cases',[]);
    warning('off','pdmat:DiscontinuousLocalValues');
    for index = 1:numel(cases)
        yalmip('clear'); rng(20260922,'twister');
        cfg = cases(index);
        operation = makeOperation(cfg);
        for warmup = 1:3, operation(); end
        elapsed = zeros(1,repetitions);
        for repetition = 1:repetitions
            if ismember(cfg.Kind,{'pipeline','construct'}), yalmip('clear'); end
            start = tic;
            for batch = 1:cfg.Batch, operation(); end
            elapsed(repetition) = toc(start)/cfg.Batch;
        end
        entry = struct('Name',cfg.Name,'Times',elapsed,'Median',median(elapsed), ...
            'Min',min(elapsed),'Max',max(elapsed),'Batch',cfg.Batch, ...
            'Primary',cfg.Primary,'ValidComparison',cfg.ValidComparison);
        results.Cases = [results.Cases entry]; %#ok<AGROW>
        fid = fopen(outputFile,'w');
        assert(fid >= 0,'Cannot write benchmark output.');
        fwrite(fid,jsonencode(results),'char'); fclose(fid);
        fprintf('OPERATOR %d/%d %s median %.9g\n',index,numel(cases),cfg.Name,entry.Median);
    end
end

function operation = makeOperation(cfg)
    if strcmp(cfg.Kind,'audited_derivative')
        P=pdvar(2,{[-2 -1 0 3],[1 1.3 2 4],[-1 0 2]},'symmetric', ...
            Degree=[3 2 2],Continuity=[0 1 Inf]);
        operation=@() rhodiff(P,repmat([-1 1],3,1)); return
    elseif strcmp(cfg.Kind,'audited_refinement')
        P=pdvar(2,{[0 .5 1],[0 .5 1]},'symmetric',Degree=[3 3]);
        Q=pdvar(2,{0:.25:1,0:.25:1},'symmetric',Degree=[3 3]);
        operation=@() P+Q; return
    elseif strcmp(cfg.Kind,'audited_product')
        P=pdvar(2,{[0 1],[0 1]},'symmetric',Degree=[8 8]);
        M=[1 .2;.3 2]; operation=@() P*M; return
    end
    grid = cfg.Grid;
    if ~iscell(grid), grid = num2cell(grid,2); end
    grid = reshape(cellfun(@(x) reshape(x,1,[]),grid,'UniformOutput',false),1,[]);
    degree = reshape(cfg.Degree,1,[]);
    shape = reshape(cfg.Shape,1,[]);
    rates = cfg.Rates;
    if numel(degree)==1, rates = reshape(rates,1,2); end
    if strcmp(cfg.Kind,'construct')
        operation = @() pdvar(shape(1),shape(2),grid,'full', ...
            Degree=degree,Continuity=reshape(cfg.Order,1,[]));
        return
    elseif strcmp(cfg.Kind,'function')
        operation = @() pdmat(grid,@(x) [1+x x*x;2-x 3+x],Degree=degree);
        return
    elseif strcmp(cfg.Kind,'pipeline')
        operation = @pipeline;
        return
    elseif strcmp(cfg.Kind,'jump')
        A = pdmat([0 .5 1],{{0,1},{10,11}},Degree=1);
        B = pdmat([0 .25 .5 .75 1],{{1},{1},{1},{1}},Degree=0);
        operation = @() A+B;
        return
    end
    if strcmp(cfg.Payload,'affine')
        A = pdvar(shape(1),shape(2),grid,'full',Degree=degree);
    else
        A = known(grid,degree,shape);
    end
    switch cfg.Kind
        case 'derivative'
            operation = @() rhodiff(A,rates);
        case {'refine','repeat'}
            target = grid;
            for axis = 1:numel(grid)
                if cfg.Axes(axis)
                    g = grid{axis};
                    target{axis} = sort([g,g(1:end-1)+.375*diff(g)]);
                end
            end
            B = known(target,zeros(size(degree)),shape);
            if strcmp(cfg.Kind,'repeat')
                final = cellfun(@(g) sort([g,g(1:end-1)+.5*diff(g)]),target,'UniformOutput',false);
                C = known(final,zeros(size(degree)),shape);
                operation = @() (A+B)+C;
            else
                operation = @() A+B;
            end
        case {'left','right','piecewise','affinefactor','general'}
            if cfg.ActiveRows, A = rhodiff(A,rates); end
            if strcmp(cfg.Kind,'general')
                B = known(grid,max(degree,1),shape);
            elseif strcmp(cfg.Kind,'piecewise')
                B = known(grid,zeros(size(degree)),[shape(2),shape(2)],true);
            elseif strcmp(cfg.Kind,'affinefactor')
                B = sdpvar(shape(2),shape(2),'full');
            elseif strcmp(cfg.Kind,'left')
                B = reshape(1:shape(1)^2,shape(1),shape(1))/7;
            else
                B = reshape(1:shape(2)^2,shape(2),shape(2))/7;
            end
            if cfg.Sparse, B = sparse(B); end
            if strcmp(cfg.Kind,'left'), operation = @() B*A;
            else, operation = @() A*B; end
        case 'direct'
            operation = @() A+A' >= 0;
        otherwise
            error('Unrecognized benchmark kind: %s',cfg.Kind);
    end
end

function A = known(grid,degree,shape,piecewise)
    % Independent power-to-Bernstein identity, outside operator timing.
    if nargin < 4, piecewise=false; end
    rows = cell(1,numel(degree));
    for k=1:numel(degree), rows{k}=0:degree(k); end
    labels = helper.combRows(rows);
    base = reshape(1:prod(shape),shape)/prod(shape);
    values = helper.mkNest(cellfun(@numel,grid)-1,@leaf);
    A = pdmat(grid,values,Degree=degree);
    function coefficients = leaf(subs)
        coefficients=cell(1,size(labels,1));
        for j=1:size(labels,1)
            x=1;
            for axis=1:numel(grid)
                if degree(axis)>0
                    g=grid{axis};
                    lo=g(subs(axis)); width=g(subs(axis)+1)-lo;
                    d=degree(axis); k=labels(j,axis); monomial=0;
                    for power=0:k
                        monomial=monomial+nchoosek(k,power)*lo^(d-power)*width^power;
                    end
                    x=x*(1+monomial);
                end
            end
            if piecewise, x=x+sum(subs.*(1:numel(subs))); end
            coefficients{j}=base*x;
        end
    end
end

function out = pipeline
    P = pdvar(2,{[0 .3 1],[-1 0 2]},'full',Degree=[2 2]);
    A = known({[0 .6 1],[-1 1 2]},[1 1],[2 2]);
    refined = P+A;
    D = rhodiff(refined,[-1 2;-2 3]);
    M=[1 2;0 1];
    out = D*M+M'*D' <= 0;
end
