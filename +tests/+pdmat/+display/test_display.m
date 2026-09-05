function tests = test_display
    % Behavioral regressions for pdmat.display.
    tests = functiontests(localfunctions);
end
function test_function_only_display_reports_source_without_sampling(testCase)
    % Display uses construction metadata and does not consume the callback.
    probes = 0;
    F = pdmat([0 2 5], @lowerOnly);
    testCase.verifyEqual(probes, 1);
    saved = F.LocalValues;
    detail = evalc("display(F)");
    short = evalc("disp(F)");
    testCase.verifyTrue(contains(detail, "Source: function"));
    testCase.verifyTrue(contains(detail, "Function handle: true"));
    testCase.verifyTrue(contains(short, "source function"));
    testCase.verifyEqual(F.LocalValues, saved);
    testCase.verifyEqual(probes, 1);

    function value = lowerOnly(x)
        % Count even repeated lower-bound probes, which would otherwise be invisible.
        probes = probes + 1;
        if x ~= 0
            error("tests:UnexpectedProbe", "Only the lower construction probe is valid.");
        end
        value = [1 2 3];
    end
end

function test_tensor_fixed_rate_display_distinguishes_active_rows(testCase)
    % One fixed vertex is still an active derivative table.
    A = pdmat({[0 2 5], [-1 3]}, @(x,y) [x+y, x-y], ...
        Degree=[1 1], RateBounds=[2 2; -3 -3]);
    D = rhodiff(A);
    detail = evalc("display(D)");
    testCase.verifyTrue(contains(detail, "pdmat with 1-by-2 matrix values"));
    testCase.verifyTrue(contains(detail, "Parameters: 2"));
    testCase.verifyTrue(contains(detail, "Physical cells: 2"));
    testCase.verifyTrue(contains(detail, "Explicit rate rows: true"));
    testCase.verifyTrue(contains(detail, "Function handle: false"));
    testCase.verifyEqual(D.coeffs([2 1]), repmat({[-1 5]},1,4));
end

function test_disp_stay_compact_while_display_prints(testCase)
    % disp should stay compact while display prints useful metadata.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);

    short = evalc("disp(A)");
    detail = evalc("display(A)");
    unnamed = evalc("display(pdmat({[0 1]}, {1, 2}, Degree=1))");

    testCase.verifyTrue(contains(short, "pdmat [1 1] over 1-D grid"));
    testCase.verifyTrue(contains(short, "source coefficient-backed"));
    testCase.verifyTrue(contains(detail, "A ="));
    testCase.verifyTrue(contains(detail, "pdmat with 1-by-1 matrix values"));
    testCase.verifyTrue(contains(detail, "rho_1: [0, 1], 2 nodes"));
    testCase.verifyTrue(contains(detail, "Coefficients per cell: 2"));
    testCase.verifyTrue(contains(unnamed, "pdmat with 1-by-1 matrix values"));
end
