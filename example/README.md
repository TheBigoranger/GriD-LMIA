# Source-grounded examples

The public v1.5.1 catalog contains five independent MATLAB scripts that reproduce small cases from papers, a textbook, and the ROLMIP manual. Run `install_pd_lmi` once, open the selected script, check the editable settings near its top, and run the script from any working directory on the MATLAB path. Each script clears YALMIP state before constructing its model. Four scripts default to SDPT3; `discrete_time_robust_stability.m` defaults to SeDuMi. Each script exposes an editable `solver` setting.

The scripts report the solver diagnostic code, a classification, elapsed time, and a source-specific comparison. A zero YALMIP problem code means that the requested solve completed, while any nonzero code must be interpreted with `yalmiperror`. In particular, numerical or resource-limit codes are reported as `unknown`, not as infeasibility.

## Univariate LPV gain

Script: [lpv_l2_gain_univariate.m](lpv_l2_gain_univariate.m).

- **Source:** Masubuchi, Kume, and Shimemura (1998), Example 1 as reproduced in the GriD-LMIA software paper.
- **Default:** One cell, degree-one $P$, univariate Putinar order 5.
- **Comparison:** Performance bound 6.051013.

## Three-parameter LPV gain

Script: [lpv_l2_gain_three_parameter.m](lpv_l2_gain_three_parameter.m).

- **Source:** Plant from Agulhari et al. (2019) and ROLMIP manual §7.2. Rate-dependent DPD-LMI from the GriD-LMIA software paper.
- **Default:** Two nodes and one physical cell per axis ($2\times2\times2$ nodes), degree-one $P$, Direct.
- **Comparison:** GriD-LMIA rate-dependent bound 1.698953. ROLMIP's static §7.2 result is 1.0540.

## Discrete-time robust stability

Script: [discrete_time_robust_stability.m](discrete_time_robust_stability.m).

- **Source:** ROLMIP manual §7.1.
- **Default:** Affine $P$, Direct.
- **Comparison:** Strict feasibility and positive residuals.

## Continuous-time robust stability

Script: [continuous_time_robust_stability.m](continuous_time_robust_stability.m).

- **Source:** Yu and Duan (2013), Example 4.9.
- **Default:** Constant $P$, Direct.
- **Comparison:** Quadratic Hurwitz certificate.

## Mass-spring-damper stability

Script: [mass_spring_damper_stability.m](mass_spring_damper_stability.m).

- **Source:** Yu and Duan (2013), Example 4.10.
- **Default:** Constant $P$, Direct.
- **Comparison:** One certified box and one non-certified box.

## Interpreting results

These examples are not unit tests and are intentionally excluded from `+tests`. Solver-dependent matrices can differ from the values printed by a source, so the scripts compare objectives, strict feasibility margins, or residual signs instead of requiring identical decision matrices.
