# Source-grounded examples

This directory contains independent MATLAB scripts that reproduce small cases from papers, a textbook, and the ROLMIP manual. Run `install_pd_lmi` once, open the selected script, check the editable settings near its top, and run the script from any working directory on the MATLAB path. Each script clears YALMIP state before constructing its model.

The scripts report the solver diagnostic code, a classification, elapsed time, and a source-specific comparison. A zero YALMIP problem code means that the requested solve completed, while any nonzero code must be interpreted with `yalmiperror`. In particular, numerical or resource-limit codes are reported as `unknown`, not as infeasibility.

| Script | Source case | Certificate and default setting | Published comparison |
| --- | --- | --- | --- |
| `masubuchi1998_univariate_sos.m` | Masubuchi, Kume, and Shimemura (1998), Example 1 as reproduced in the GriD-LMIA software paper | One cell, degree-one $P$, univariate Putinar order 5 | Performance bound 6.051013 |
| `agulhari2019_three_parameter_direct.m` | Plant from Agulhari et al. (2019) and ROLMIP manual §7.2. Rate-dependent DPD-LMI from the GriD-LMIA software paper | $2\times2\times2$ grid, degree-one $P$, Direct | GriD-LMIA rate-dependent bound 1.698953. ROLMIP's static §7.2 result is 1.0540 |
| `delay_case_a_theorem2_sos.m` | Delay-system paper, Case A and Theorem 2 | Degree-two $P$, one-cell FullBox | Rounded lower bound 3.687 |
| `delay_case_a_theorem3_direct_10cell.m` | Delay-system paper, Case A and Theorem 3 | $(N,d)=(3,3)$, ten cells, Direct | Accepted 5.151 and rejected 5.152 |
| `rolmip_manual_section_7_1_discrete_stability.m` | ROLMIP manual §7.1 | Affine $P$, Direct | Strict feasibility and positive residuals |
| `yu_duan2013_example_4_9_affine_stability.m` | Yu and Duan (2013), Example 4.9 | Constant $P$, Direct | Quadratic Hurwitz certificate |
| `yu_duan2013_example_4_10_mass_spring_damper.m` | Yu and Duan (2013), Example 4.10 | Constant $P$, Direct | One certified box and one non-certified box |

These examples are not unit tests and are intentionally excluded from `+tests`. Solver-dependent matrices can differ from the values printed by a source, so the scripts compare objectives, strict feasibility margins, or residual signs instead of requiring identical decision matrices.
