function [results, coverage] = run_coverage
    %RUN_COVERAGE Run the unit suite and enforce production-code coverage.
    %
    %   Syntax:
    %     [results, coverage] = tests.run_coverage()
    %
    %   The coverage scope contains the production classes, package helpers,
    %   and install_pd_lmi.m. Test sources are deliberately excluded.

    import matlab.unittest.TestRunner
    import matlab.unittest.TestSuite
    import matlab.unittest.plugins.CodeCoveragePlugin
    import matlab.unittest.plugins.codecoverage.CoverageResult

    packageRoot = fileparts(fileparts(mfilename("fullpath")));
    testRoot = fullfile(packageRoot, "+tests");
    suite = TestSuite.fromFolder(testRoot, "IncludingSubfolders", true);
    runner = TestRunner.withTextOutput;
    sourceFolders = ["@pdbase", "@pdmat", "@pdvar", "@pdlmi", "+helper"];
    coverageOutputs = cell(1, numel(sourceFolders) + 1);

    for sourceIndex = 1:numel(sourceFolders)
        coverageOutputs{sourceIndex} = CoverageResult;
        plugin = CodeCoveragePlugin.forFolder( ...
            fullfile(packageRoot, sourceFolders(sourceIndex)), ...
            "IncludingSubfolders", true, ...
            "MetricLevel", "decision", ...
            "Producing", coverageOutputs{sourceIndex});
        runner.addPlugin(plugin);
    end

    coverageOutputs{end} = CoverageResult;
    runner.addPlugin(CodeCoveragePlugin.forFile( ...
        fullfile(packageRoot, "install_pd_lmi.m"), ...
        "MetricLevel", "decision", ...
        "Producing", coverageOutputs{end}));

    results = runner.run(suite);
    assertSuccess(results);
    coverage = summarizeCoverage(coverageOutputs);

    statementBaseline = struct("Covered", 3292, "Total", 3408);
    decisionBaseline = struct("Covered", 1652, "Total", 1762);
    coverage.Statement.Baseline = statementBaseline;
    coverage.Decision.Baseline = decisionBaseline;

    assertCoverage(coverage.Statement, statementBaseline, "statement");
    assertCoverage(coverage.Decision, decisionBaseline, "decision");

    fprintf(1, 'Statement coverage: %d/%d (%.2f%%)\n', ...
        coverage.Statement.Covered, coverage.Statement.Total, ...
        coverage.Statement.Percentage);
    fprintf(1, 'Decision coverage:  %d/%d (%.2f%%)\n', ...
        coverage.Decision.Covered, coverage.Decision.Total, ...
        coverage.Decision.Percentage);
end

function coverage = summarizeCoverage(coverageOutputs)
    statementCovered = 0;
    statementTotal = 0;
    decisionCovered = 0;
    decisionTotal = 0;

    for outputIndex = 1:numel(coverageOutputs)
        result = coverageOutputs{outputIndex}.Result;
        statement = coverageSummary(result, "statement");
        decision = coverageSummary(result, "decision");
        statementCovered = statementCovered + sum(statement(:, 1));
        statementTotal = statementTotal + sum(statement(:, 2));
        decisionCovered = decisionCovered + sum(decision(:, 1));
        decisionTotal = decisionTotal + sum(decision(:, 2));
    end

    coverage.Statement = metricSummary(statementCovered, statementTotal);
    coverage.Decision = metricSummary(decisionCovered, decisionTotal);
end

function summary = metricSummary(covered, total)
    summary = struct("Covered", covered, "Total", total, ...
        "Percentage", 100 * covered / total);
end

function assertCoverage(actual, baseline, label)
    baselinePercentage = 100 * baseline.Covered / baseline.Total;
    if actual.Percentage + 10 * eps(baselinePercentage) < baselinePercentage
        error("tests:CoverageRegression", ...
            "%s coverage regressed from %d/%d (%.2f%%) to %d/%d (%.2f%%).", ...
            label, baseline.Covered, baseline.Total, baselinePercentage, ...
            actual.Covered, actual.Total, actual.Percentage);
    end
    if actual.Total < baseline.Total
        error("tests:CoverageDenominatorRegression", ...
            "%s coverage total decreased from %d to %d; inspect uncovered locations.", ...
            label, baseline.Total, actual.Total);
    end
end
