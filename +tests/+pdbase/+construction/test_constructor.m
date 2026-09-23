function tests = test_constructor
    % Behavioral regressions for pdbase.constructor.
    tests = functiontests(localfunctions);
end

function test_strict_later_tensor_rate_payload_and_valid_neighbor(testCase)
    % Strict validation reaches the last coefficient of the last physical cell.
    grid = {[0 2 5],[-3 1 6]};
    vals = {{ {1,2,3;4,5,6}, {7,8,9;10,11,12} }, ...
        { {13,14,15;16,17,18}, {19,20,21;22,23,24} }};
    A=pdbase(grid,[1 1],[0 2],vals,RateBounds=[3 3;-2 5],ValidationMode="strict");
    testCase.verifyEqual(A.LocalValues,vals);
    testCase.verifyEqual(A.NumRateRows,2);
    bad=vals; bad{2}{2}{2,3}=NaN;
    testCase.verifyError(@() pdbase(grid,[1 1],[0 2],bad, ...
        RateBounds=[3 3;-2 5],ValidationMode="strict"),"pdbase:InvalidCoefficientPayload");
    testCase.verifyEqual(A.LocalValues,vals);
end

function test_scalar_construction_populate_default_coefficient(testCase)
    % Scalar construction should populate default coefficient-backed state.
    obj = pdbase({[0 1 3]}, [2 3], 1);

    testCase.verifyEqual(obj.MatrixSize, [2 3]);
    testCase.verifyEqual(obj.Degree, 1);
    testCase.verifyFalse(obj.IsContinuous);
    testCase.verifyFalse(obj.ContainsDecision);
    testCase.verifyEmpty(obj.RateBounds);

    % Default objects are coefficient-backed zeros, not sampled grid data.
    testCase.verifyEqual(obj.SourceSummary, "coefficient-backed");
    testCase.verifyEqual(obj.npar(), 1);
    testCase.verifyEqual(obj.ncell(), 2);
    testCase.verifyEqual(obj.ncoeff(), 2);
    testCase.verifyEqual(size(obj), [2 3]);
    testCase.verifyEqual(size(obj, 1), 2);
    testCase.verifyEqual(size(obj, 3), 1);
end

function test_matrix_protocol_methods_report_stored_payload(testCase)
    % Shared matrix protocol methods should report the stored payload shape.
    obj = pdbase({[0 1]}, [2 3], 0);

    testCase.verifyEqual(height(obj), 2);
    testCase.verifyEqual(width(obj), 3);
    testCase.verifyEqual(length(obj), 3);
    testCase.verifyEqual(numel(obj), 6);
    testCase.verifyEqual(ndims(obj), 2);
    testCase.verifyEqual(+obj, obj);
    testCase.verifyEqual(squeeze(obj), obj);

    [m, n, trailing] = size(obj);
    testCase.verifyEqual([m n trailing], [2 3 1]);
    testCase.verifyEqual(numel(obj, 1), 1);
end

function test_direct_pdbase_operands_create_ambiguous_matlab(testCase)
    % Direct pdbase operands must not create ambiguous MATLAB object arrays.
    obj = pdbase({[0 1]}, [1 1], 0);
    known = pdmat({[0 1]}, {1, 2}, Degree=1);

    testCase.verifyError(@() horzcat(obj, obj), ...
        "pdbase:UnsupportedConcatenation");
    testCase.verifyError(@() vertcat(obj, obj), ...
        "pdbase:UnsupportedConcatenation");
    testCase.verifyError(@() cat(1, obj, obj), ...
        "pdbase:UnsupportedConcatenation");
    testCase.verifyError(@() cat(2, obj, obj), ...
        "pdbase:UnsupportedConcatenation");
    testCase.verifyError(@() horzcat(obj, known), ...
        "pdbase:UnsupportedConcatenation");
    testCase.verifyError(@() horzcat(known, obj), ...
        "pdbase:UnsupportedConcatenation");
end

function test_tensor_construction_preserve_explicit_flags_rate(testCase)
    % Tensor construction should preserve explicit flags and rate bounds.
    obj = pdbase({[0 1 2], [10 20]}, [1 1], 2, [], ...
        IsContinuous=true, ContainsDecision=true, ...
        RateBounds=[-1 1; -2 2], SourceSummary="test-coefficients");

    testCase.verifyEqual(obj.GridInfo.NumNodes, [3 2]);
    testCase.verifyTrue(obj.IsContinuous);
    testCase.verifyTrue(obj.ContainsDecision);
    testCase.verifyEqual(obj.RateBounds, [-1 1; -2 2]);
    testCase.verifyEqual(obj.SourceSummary, "test-coefficients");
    testCase.verifyEqual(obj.npar(), 2);
    testCase.verifyEqual(obj.ncell(), 2);
    testCase.verifyEqual(obj.ncoeff(), 9);
end

function test_continuity_metadata_and_legacy_alias(testCase)
    % Continuity is stored once; IsContinuous is its dependent compatibility view.
    grid = {[0 1 2], [10 20]};
    direct = pdbase(grid, [1 1], [2 1], Continuity=[1 -1]);
    legacyTrue = pdbase(grid, [1 1], [1 1], IsContinuous=true);
    legacyFalse = pdbase(grid, [1 1], [1 1], IsContinuous=false);

    testCase.verifyEqual(direct.Continuity, [1 -1]);
    testCase.verifyFalse(direct.IsContinuous);
    testCase.verifyEqual(legacyTrue.Continuity, [0 0]);
    testCase.verifyTrue(legacyTrue.IsContinuous);
    testCase.verifyEqual(legacyFalse.Continuity, [-1 -1]);
    testCase.verifyFalse(legacyFalse.IsContinuous);
end

function test_continuity_alias_conflicts_and_invalid_values(testCase)
    grid = {[0 1], [10 20]};
    testCase.verifyError(@() pdbase(grid, [1 1], [1 1], ...
        Continuity=0, IsContinuous=true), ...
        "pdbase:ConflictingContinuityOptions");
    testCase.verifyError(@() pdbase(grid, [1 1], [1 1], ...
        IsContinuous=true, Continuity=0), ...
        "pdbase:ConflictingContinuityOptions");
    bad = {[], [0 1 2], [0.5 1], [NaN 0], [-2 0], "C1"};
    for k = 1:numel(bad)
        testCase.verifyError(@() pdbase(grid, [1 1], [1 1], ...
            Continuity=bad{k}), "pdbase:InvalidContinuity");
    end
end

function test_named_metadata_may_omit_optional_localvalues(testCase)
    % Named metadata may omit the optional LocalValues position.
    obj = pdbase({[0 1]}, [1 1], 0, ...
        IsContinuous=1, ContainsDecision=true, SourceSummary="option-parser");

    testCase.verifyTrue(obj.IsContinuous);
    testCase.verifyTrue(obj.ContainsDecision);
    testCase.verifyEqual(obj.SourceSummary, "option-parser");
end

function test_ratebounds_only_stored_rate_metadata_state(testCase)
    % RateBounds should be the only stored rate-metadata state.
    ordinary = pdbase({[0 1]}, [1 1], 0);
    bounded = pdbase({[0 1]}, [1 1], 0, [], RateBounds=[-1 1]);

    testCase.verifyFalse(isprop(ordinary, "HasRateDependence"));
    testCase.verifyEmpty(ordinary.RateBounds);
    testCase.verifyEqual(bounded.RateBounds, [-1 1]);
end

function test_explicit_internal_row_counts_require_matching(testCase)
    % Explicit internal row counts require matching distinct rate vertices.
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, [], ...
        NumRateRows=1), "pdbase:InvalidRateBounds");
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, [], ...
        RateBounds=[-1 1], NumRateRows=1), ...
        "pdbase:InvalidRateBounds");
end


function test_public_state_properties_inspectable_but_mutable(testCase)
    % Public state properties should be inspectable but not mutable.
    obj = pdbase({[0 1]}, [1 1], 0);

    testCase.verifyError(@() setSummary(obj), "MATLAB:class:SetProhibited");
    testCase.verifyError(@() setDeg(obj), "MATLAB:class:SetProhibited");
    testCase.verifyError(@() setContinuity(obj), "MATLAB:class:SetProhibited");
    testCase.verifyError(@() setIsContinuous(obj), "MATLAB:class:SetProhibited");
end

function test_scalar_grids_expose_flat_cell_coefficient(testCase)
    % Scalar grids should expose flat per-cell coefficient storage.
    localValues = {{11, 12, 13}, {21, 22, 23}};
    obj = pdbase({[0 1 2]}, [1 1], 2, localValues);

    % A scalar grid still stores one flat coefficient cell per physical cell.
    testCase.verifyEqual(obj.LocalValues{1}, {11, 12, 13});
    testCase.verifyEqual(obj.coeffs(2), {21, 22, 23});
    testCase.verifyEqual(obj.coeffs({1}), {11, 12, 13});
    testCase.verifyEqual(obj.ncoeff(), 3);
end

function test_tensor_grids_preserve_nested_physical_cell(testCase)
    % Tensor grids should preserve nested physical-cell access.
    localValues = {
        {mkCoeff(110), mkCoeff(120)}, ...
        {mkCoeff(210), mkCoeff(220)}
        };
    obj = pdbase({[0 1 2], [10 20 30]}, [1 1], 1, localValues);

    testCase.verifyEqual(obj.LocalValues{2}{1}, mkCoeff(210));
    testCase.verifyEqual(obj.coeffs([1 2]), mkCoeff(120));
    testCase.verifyEqual(obj.coeffs({2, 2}), mkCoeff(220));
    testCase.verifyEqual(obj.ncoeff(), 4);
end

function test_rate_bounds_live_object_inside_localvalues(testCase)
    % Rate bounds should live on the object, not inside LocalValues.
    obj = pdbase({[0 1], [10 20]}, [1 1], 0, [], ...
        RateBounds=[-1 1; -2 2]);

    coeffs = obj.coeffs([1 1]);
    testCase.verifyEqual(obj.RateBounds, [-1 1; -2 2]);
    testCase.verifyEqual(numel(coeffs), 1);
    testCase.verifyEqual(coeffs{1}, 0);
end

function test_tensor_localvalues_nested_by_physical_cell(testCase)
    % Tensor LocalValues must be nested by physical cell dimensions.
    flatCells = {mkCoeff(11), mkCoeff(12), mkCoeff(21), mkCoeff(22)};

    testCase.verifyError(@() pdbase({[0 1 2], [10 20 30]}, [1 1], 1, flatCells), ...
        "pdbase:InvalidLocalValues");
end

function test_each_physical_cell_contain_exactly_ncoeff(testCase)
    % Each physical cell must contain exactly ncoeff local coefficients.
    badValues = {{1}, {2, 3}};

    testCase.verifyError(@() pdbase({[0 1 2]}, [1 1], 1, badValues), ...
        "pdbase:InvalidCoefficientCell");
end

function test_coeffs_reject_out_range_wrong_width(testCase)
    % coeffs should reject out-of-range, wrong-width, or noninteger subscripts.
    obj = pdbase({[0 1 2], [10 20]}, [1 1], 0);

    testCase.verifyError(@() obj.coeffs([0 1]), "pdbase:InvalidCellSubs");
    testCase.verifyError(@() obj.coeffs([3 1]), "pdbase:InvalidCellSubs");
    testCase.verifyError(@() obj.coeffs([1]), "pdbase:InvalidCellSubs");
    testCase.verifyError(@() obj.coeffs([1 1.5]), "pdbase:InvalidCellSubs");
    testCase.verifyError(@() obj.coeffs({1, 1, 1}), "pdbase:InvalidCellSubs");
end

function test_grid_input_nonempty_cell_array_grid(testCase)
    % Grid input should be a nonempty cell array of grid vectors.
    testCase.verifyError(@() pdbase([0 1], [1 1], 0), "pdbase:InvalidGrid");
    testCase.verifyError(@() pdbase({}, [1 1], 0), "pdbase:InvalidGrid");
end

function test_grid_vectors_finite_strictly_increasing_numeric(testCase)
    % Grid vectors should be finite, strictly increasing numeric nodes.
    testCase.verifyError(@() pdbase({[0 1 1]}, [1 1], 0), "pdbase:InvalidGridVector");
    testCase.verifyError(@() pdbase({[0 2 1]}, [1 1], 0), "pdbase:InvalidGridVector");
    testCase.verifyError(@() pdbase({[0 Inf]}, [1 1], 0), "pdbase:InvalidGridVector");
    testCase.verifyError(@() pdbase({[0 NaN]}, [1 1], 0), "pdbase:InvalidGridVector");
end

function test_degree_accepts_only_scalar_or_finite(testCase)
    % Degree accepts only a scalar or one finite integer per parameter.
    grid = {[0 1], [10 20]};
    valid = pdbase(grid, [1 1], [0; 2]);
    testCase.verifyEqual(valid.Degree, [0 2]);

    bad = {[], [1 2 3], [1 2; 3 4], -1, 1.5, Inf, NaN, "one"};
    for k = 1:numel(bad)
        testCase.verifyError(@() pdbase(grid, [1 1], bad{k}), ...
            "pdbase:InvalidDegree");
    end
end

function test_matrixsize_positive_2_d_integer_size(testCase)
    % MatrixSize should be a positive 2-D integer size vector.
    testCase.verifyError(@() pdbase({[0 1]}, [1 0], 0), "pdbase:InvalidMatrixSize");
    testCase.verifyError(@() pdbase({[0 1]}, [1 1 1], 0), "pdbase:InvalidMatrixSize");
    testCase.verifyError(@() pdbase({[0 1]}, [1.5 1], 0), "pdbase:InvalidMatrixSize");
end

function test_ratebounds_match_parameter_count_contain_finite(testCase)
    % RateBounds should match parameter count and contain finite lower/upper pairs.
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, [], RateBounds=[0 1; -1 1]), ...
        "pdbase:InvalidRateBounds");
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, [], RateBounds=[1 -1]), ...
        "pdbase:InvalidRateBounds");
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, [], RateBounds=[0 Inf]), ...
        "pdbase:InvalidRateBounds");
end

function test_localvalues_fail_missing_cells_or_wrong(testCase)
    % LocalValues should fail for missing cells or wrong coefficient counts.
    testCase.verifyError(@() pdbase({[0 1 2]}, [1 1], 1, {{1, 2}}), ...
        "pdbase:InvalidLocalValues");
    testCase.verifyError(@() pdbase({[0 1 2]}, [1 1], 1, {{1}, {2, 3}}), ...
        "pdbase:InvalidCoefficientCell");
end

function test_plain_payloads_stay_finite_real_numeric(testCase)
    % Plain payloads must stay finite real numeric matrices at pdbase level.
    invalidPayloads = { ...
        [1 NaN; 0 1], ...
        [1 Inf; 0 1], ...
        [1 1i; 0 1], ...
        ['a' 'b'; 'c' 'd'], ...
        {1 2; 3 4}, ...
        repmat(struct("Constant", 0), 2, 2)};

    for k = 1:numel(invalidPayloads)
        testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, ...
            scalarVals(invalidPayloads{k})), "pdbase:InvalidCoefficientPayload");
    end
end

function test_pdbase_storage_accepts_real_2_d(testCase)
    % pdbase storage accepts real 2-D YALMIP payloads for pdvar subclasses.
    X = sdpvar(2, 2, 'full');

    obj = pdbase({[0 1]}, [2 2], 0, scalarVals(X), ...
        ContainsDecision=true);

    coeffs = obj.coeffs(1);
    testCase.verifyTrue(isa(coeffs{1}, "sdpvar"));
    testCase.verifyEqual(size(coeffs{1}), [2 2]);
    testCase.verifyTrue(obj.ContainsDecision);
end

function test_rate_affine_payload_structs_preserve_constant(testCase)
    % Rate-affine payload structs should preserve constant and rate parts.
    payload = ratePayload(2);
    rb = [-1 1; -2 2];

    obj = pdbase({[0 1], [10 20]}, [2 2], 0, tensorVals(payload), ...
        RateBounds=rb);

    coeffs = obj.coeffs([1 1]);
    testCase.verifyEqual(obj.RateBounds, rb);
    testCase.verifyEqual(coeffs{1}.Constant, payload.Constant);
    testCase.verifyEqual(coeffs{1}.Rate, payload.Rate);
end

function test_malformed_rate_affine_structs_fail_payload(testCase)
    % Malformed rate-affine structs should fail payload validation.
    payload = ratePayload(1);

    nonCellRate = payload;
    nonCellRate.Rate = zeros(2);
    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, ...
        scalarVals(nonCellRate), RateBounds=[-1 1]), ...
        "pdbase:InvalidCoefficientPayload");

    wrongRateLength = payload;
    wrongRateLength.Rate = {zeros(2), zeros(2)};
    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, ...
        scalarVals(wrongRateLength), RateBounds=[-1 1]), ...
        "pdbase:InvalidCoefficientPayload");

    invalidConstant = payload;
    invalidConstant.Constant = [1 NaN; 0 1];
    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, ...
        scalarVals(invalidConstant), RateBounds=[-1 1]), ...
        "pdbase:InvalidCoefficientPayload");

    invalidRateEntry = payload;
    invalidRateEntry.Rate{1} = [1 Inf; 0 1];
    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, ...
        scalarVals(invalidRateEntry), RateBounds=[-1 1]), ...
        "pdbase:InvalidCoefficientPayload");
end

function test_rate_affine_payloads_require_explicit_ratebounds(testCase)
    % Rate-affine payloads should require explicit RateBounds.
    payload = ratePayload(1);

    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, scalarVals(payload)), ...
        "pdbase:InvalidRateBounds");
    testCase.verifyError(@() pdbase({[0 1]}, [2 2], 0, scalarVals(payload), ...
        RateBounds=[]), "pdbase:InvalidRateBounds");
end

function test_supplying_ratebounds_rate_domain_metadata(testCase)
    % Supplying RateBounds should retain the rate domain metadata.
    obj = pdbase({[0 1]}, [1 1], 0, [], RateBounds=[-1 1]);

    testCase.verifyEqual(obj.RateBounds, [-1 1]);
end

function test_valid_normalized_storage_has_identical_public(testCase)
    % Valid normalized storage has identical public state in every mode.
    grid = {[0 1 2]};
    vals = {{1, 2}, {2, 3}};

    implicit = pdbase(grid, [1 1], 1, vals);
    fast = pdbase(grid, [1 1], 1, vals, ValidationMode="FAST");
    strict = pdbase(grid, [1 1], 1, vals, ValidationMode='Strict');

    testCase.verifyEqual(implicit.GridInfo, fast.GridInfo);
    testCase.verifyEqual(implicit.LocalValues, fast.LocalValues);
    testCase.verifyEqual(fast.LocalValues, strict.LocalValues);
    testCase.verifyFalse(isprop(implicit, "ValidationMode"));
end

function test_fast_trusts_later_generated_cells_strict(testCase)
    % Fast trusts later generated cells; strict remains the diagnostic mode.
    grid = {[0 1 2]};

    wrongCount = {{1, 2}, {3}};
    fast = pdbase(grid, [1 1], 1, wrongCount, ValidationMode="fast");
    testCase.verifyEqual(fast.LocalValues, wrongCount);
    testCase.verifyError(@() pdbase(grid, [1 1], 1, wrongCount, ...
        ValidationMode="strict"), "pdbase:InvalidCoefficientCell");

    wrongSize = {{eye(2), eye(2)}, {1, eye(2)}};
    fast = pdbase(grid, [2 2], 1, wrongSize, ValidationMode="fast");
    testCase.verifyEqual(fast.LocalValues, wrongSize);
    testCase.verifyError(@() pdbase(grid, [2 2], 1, wrongSize, ...
        ValidationMode="strict"), "pdbase:InvalidCoefficientPayload");

    mixedRows = {{1, 2}, {3, 4; 5, 6}};
    fast = pdbase(grid, [1 1], 1, mixedRows, ...
        RateBounds=[-1 1], ValidationMode="fast");
    testCase.verifyEqual(fast.LocalValues, mixedRows);
    testCase.verifyError(@() pdbase(grid, [1 1], 1, mixedRows, ...
        RateBounds=[-1 1], ValidationMode="strict"), ...
        "pdbase:InvalidCoefficientRows");
end

function test_missing_nonscalar_nontext_empty_unsupported_modes(testCase)
    % Missing, nonscalar, nontext, empty, and unsupported modes are rejected.
    make = @(mode) pdbase({[0 1]}, [1 1], 0, {{1}}, ...
        ValidationMode=mode);
    bad = {42, ["fast", "strict"], string(missing), '', "sample"};
    for k = 1:numel(bad)
        testCase.verifyError(@() make(bad{k}), ...
            "pdbase:InvalidValidationMode");
    end
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, {{1}}, ...
        "ValidationMode"), "pdbase:InvalidValidationMode");
end

function test_fast_construction_may_trust_generated_later(testCase)
    % Fast construction may trust generated later cells; strict elevation must not.
    grid = {[0 1 2], [10 20]};
    degree = [1 0];
    valid = helper.mkNest([2 1], ...
        @(subs) {subs(1), subs(1) + 1});

    wrongCount = valid;
    wrongCount{2}{1} = {3};
    countSource = pdbase(grid, [1 1], degree, wrongCount, ...
        ValidationMode="fast");
    testCase.verifyError(@() countSource.elevate([0 1], "strict"), ...
        "pdbase:InvalidCoefficientCell");

    wrongPayload = valid;
    wrongPayload{2}{1} = {3, "bad"};
    payloadSource = pdbase(grid, [1 1], degree, wrongPayload, ...
        ValidationMode="fast");
    testCase.verifyError(@() payloadSource.elevate([0 1], "strict"), ...
        "pdbase:InvalidCoefficientPayload");

    wrongSize = valid;
    wrongSize{2}{1} = {3, [4 5]};
    sizeSource = pdbase(grid, [1 1], degree, wrongSize, ...
        ValidationMode="fast");
    testCase.verifyError(@() sizeSource.elevate([0 1], "strict"), ...
        "pdbase:InvalidCoefficientPayload");
end
function setSummary(obj)
    % Local setter helper should trigger the read-only property guard.
    obj.SourceSummary = "manual";
end

function setDeg(obj)
    % Local setter helper should exercise the Degree immutability path.
    obj.Degree = 3;
end

function setContinuity(obj)
    % Both the stored bound and derived compatibility property are read-only.
    obj.Continuity = 0;
end

function setIsContinuous(obj)
    obj.IsContinuous = true;
end
function c = mkCoeff(offset)
    % Keep tensor-cell payloads visually distinct while preserving flat order.
    c = {offset + 1, offset + 2, offset + 3, offset + 4};
end
function localValues = scalarVals(payload)
    % Scalar grids still store one flat coefficient cell inside LocalValues.
    localValues = {{payload}};
end

function localValues = tensorVals(payload)
    % Tensor grids use nested physical-cell storage even for a single cell.
    localValues = {{{payload}}};
end

function payload = ratePayload(nPar)
    % Build a valid rate-affine payload with one rate matrix per parameter.
    payload = struct("Constant", eye(2), "Rate", {cell(1, nPar)});
    for k = 1:nPar
        payload.Rate{k} = k * ones(2);
    end
end
