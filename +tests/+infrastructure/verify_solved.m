function verify_solved(testCase, constraints)
    %VERIFY_SOLVED Require finite values and normalized cone/equality residuals.
    for k=1:length(constraints)
        cone=constraints(k);
        matrix=value(sdpvar(cone));
        testCase.assertTrue(all(isfinite(matrix(:))));
        scale=max(1,norm(matrix,'fro'));
        if is(cone,'equality')
            error=norm(matrix,'fro');
        elseif is(cone,'sdp')
            error=max(0,-min(eig((matrix+matrix')/2)));
        else
            error=max(0,-min(matrix(:)));
        end
        testCase.verifyLessThanOrEqual(error/scale,1e-7);
    end
end
