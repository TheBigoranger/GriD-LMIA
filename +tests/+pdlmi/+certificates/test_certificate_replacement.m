function tests = test_certificate_replacement
    % Public pdlmi.certificate_replacement behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_rate_replacement_preserves_rectangular_residual(testCase)
    % Replacement must retain every affine target, including fixed-rate axes.
    state = warning('off', 'pdlmi:ElementwiseInequality');
    cleanup = onCleanup(@() warning(state)); %#ok<NASGU>
    grid = {[0 1 4], [-2 0 3]};
    P = pdvar(2, 1, grid, 'full', Degree=[0 2], ...
        RateBounds=[2 2; -1 3]);
    R = [2 -1; 3 4] * rhodiff(P) + [5; -7];
    direct = R <= 0;
    original = direct.useFullBox([0 2]);
    saved = original;
    selectors = {@(x) x.usePolya([1 2]), ...
        @(x) x.usePutinar([0 2]), @(x) x.useSpPut(2, [0 2]), ...
        @(x) x.useSpBox(2, [0 2]), @(x) x.useFullBox([0 1])};
    for k = 1:numel(selectors)
        actual = selectors{k}(original);
        expected = selectors{k}(direct);
        for field = string(properties(direct))'
            if field == "Constraints", continue; end
            testCase.verifyEqual(actual.(field), expected.(field));
        end
        tests.infrastructure.verify_constraints(testCase, ...
            actual.Constraints, expected.Constraints, true);
        tests.infrastructure.verify_constraints(testCase, ...
            original.Constraints, saved.Constraints, false);
        testCase.verifyEqual(actual.Residual.LocalValues, R.LocalValues);
        testCase.verifyEqual(actual.Residual.NumRateRows, 2);
    end
end

function test_rejected_replacement_leaves_prior_certificate_usable(testCase)
    % Invalid parameters cannot partially replace a previously assembled family.
    P = pdvar(2, [0 1 4], Degree=4);
    original = useSpPut(P >= 0, 2, 2);
    saved = original;
    invalid = {@() original.usePolya(-1), ...
        @() original.usePutinar(1), @() original.useSpPut(0, 2), ...
        @() original.useSpBox(1, 1), @() original.useFullBox(NaN)};
    ids = ["pdlmi:InvalidPolyaDegree", "pdlmi:PutinarOrderTooLow", ...
        "pdlmi:InvalidCliqueSize", "pdlmi:SparseFullBoxOrderTooLow", ...
        "pdlmi:InvalidFullBoxOrder"];
    for k = 1:numel(invalid)
        testCase.verifyError(invalid{k}, ids(k));
        for field = string(properties(original))'
            if field == "Constraints", continue; end
            testCase.verifyEqual(original.(field), saved.(field));
        end
        tests.infrastructure.verify_constraints(testCase, ...
            original.Constraints, saved.Constraints, false);
    end
    recovered = original.useSpBox(1, 2);
    direct = P >= 0;
    tests.infrastructure.verify_constraints(testCase, ...
        recovered.Constraints, direct.Constraints, false);
end

function test_every_source_and_destination_family(testCase)
    P=pdvar(1,[0 2 5],Degree=2);
    direct=P>=0;
    selectors={@(x) x.usePolya(2),@(x) x.usePutinar(2), ...
        @(x) x.useSpPut(2,2),@(x) x.useSpBox(2,2),@(x) x.useFullBox(2)};
    sources=[{direct},cellfun(@(f) f(direct),selectors,'UniformOutput',false)];
    fields=properties(direct);
    for src=1:numel(sources)
        saved=sources{src};
        for dst=1:numel(selectors)
            actual=selectors{dst}(saved); fresh=selectors{dst}(direct);
            for k=1:numel(fields)
                field=fields{k};
                if strcmp(field,'Constraints'), continue; end
                testCase.verifyEqual(actual.(field),fresh.(field));
            end
            testCase.verifyEqual(actual.Residual.LocalValues,P.LocalValues);
            tests.infrastructure.verify_constraints(testCase,actual.Constraints,fresh.Constraints,true);
            tests.infrastructure.verify_constraints(testCase,sources{src}.Constraints,saved.Constraints,false);
        end
    end
end
