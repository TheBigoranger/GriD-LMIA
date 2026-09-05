function verify_constraints(testCase, actual, expected, alignAuxiliary)
    %VERIFY_CONSTRAINTS Compare expressions; optionally align fresh Gram block roles.
    testCase.assertEqual(numel(actual),numel(expected));
    from=[]; to=[];
    if alignAuxiliary
        shared=intersect(getvariables([actual{:}]),getvariables([expected{:}]));
        for k=1:numel(actual)
            if is(actual{k},'equality'), continue; end
            a=setdiff(getvariables(actual{k}),shared,'stable');
            b=setdiff(getvariables(expected{k}),shared,'stable');
            testCase.assertEqual(numel(a),numel(b));
            from=[from a]; to=[to b]; %#ok<AGROW>
        end
    end
    for k=1:numel(actual)
        testCase.verifyEqual(is(actual{k},'equality'),is(expected{k},'equality'));
        testCase.verifyEqual(is(actual{k},'sdp'),is(expected{k},'sdp'));
        expression=sdpvar(actual{k});
        if ~isempty(from), expression=replace(expression,recover(from),recover(to)); end
        tests.infrastructure.verify_expr(testCase,expression,sdpvar(expected{k}));
    end
end
