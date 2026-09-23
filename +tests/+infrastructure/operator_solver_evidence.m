function results = operator_solver_evidence(outputFile)
    %OPERATOR_SOLVER_EVIDENCE Retain matched bounded-real solve certificates.
    % Each fixed continuity order is a separate optimization problem.
    grid=[0 .2 .65 1];
    solver=tests.infrastructure.select_sdp_solver();
    options=sdpsettings('solver',solver,'verbose',0);
    results=struct('Solver',solver,'Matlab',version,'Cases',[]);
    for order=[0 1 2 Inf]
        yalmip('clear');
        A=pdmat(grid,@(x) [-1 .5;-1 -2]+x*[-1.3 -20;2 -10],Degree=1);
        B=pdmat(grid,@(x) [1 -4;-1 -1]+x*[2.2 .5;-6 -5],Degree=1);
        P=pdvar(2,grid,Degree=3,Continuity=order);
        gamma=pdvar(1,grid,Degree=0);
        derivative=rhodiff(P,[-1 1]);
        bounded=[derivative+P*A+A'*P,P*B,eye(2); ...
            B'*P,-gamma*eye(2),zeros(2);eye(2),zeros(2),-gamma*eye(2)]<=0;
        positive=P>=0;
        F=[bounded.toYalmip,positive.toYalmip];
        objective=gamma.LocalValues{1}{1};
        solution=optimize(F,objective,options);
        assert(solution.problem==0,solution.info);
        objectiveValue=value(objective); assert(isfinite(objectiveValue));
        maximum=0;
        for index=1:length(F)
            cone=F(index); matrix=value(sdpvar(cone));
            assert(all(isfinite(matrix(:))));
            if is(cone,'equality'), violation=norm(matrix,'fro');
            elseif is(cone,'sdp'), violation=max(0,-min(eig((matrix+matrix')/2)));
            else, violation=max(0,-min(matrix(:))); end
            maximum=max(maximum,violation/max(1,norm(matrix,'fro')));
        end
        assert(maximum<=1e-7);
        impossible=optimize([P>=2*eye(2),P<=eye(2)],[],options);
        assert(impossible.problem==1,impossible.info);
        results.Cases=[results.Cases,struct('Order',string(order), ...
            'Objective',objectiveValue,'Problem',solution.problem, ...
            'MaxNormalizedResidual',maximum,'InfeasibleProblem',impossible.problem)]; %#ok<AGROW>
        fprintf('MATCHED_SOLVER C%g objective %.15g residual %.6g\n',order,objectiveValue,maximum);
    end
    fid=fopen(outputFile,'w'); assert(fid>=0);
    fwrite(fid,jsonencode(results),'char'); fclose(fid);
end
