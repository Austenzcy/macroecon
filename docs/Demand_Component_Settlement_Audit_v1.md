# Demand Component Settlement Audit v1

Date: 2026-07-29

Scope: audit the IS-LM demand component data system after adding `C_value`, `I_value`, and `G_value` to the existing 11 IS-LM levels. This audit does not change policy costs, victory conditions, map art, hover behavior, card art, DialogueOverlay, fonts, or the macro model equations.

## Data Flow

Authority order:

1. `data/scenarios.json` provides level initial state fields: `Y`, `i`, `Debt`, legacy qualitative `C` / `I` / `G`, and numeric `C_value` / `I_value` / `G_value` plus `C_status` / `I_status` / `G_status`.
2. `GameState._load_initial_state()` deep-copies scenario initial state and normalizes it through `ISLMDemandComponents.normalize_initial_state()`.
3. `PolicyDesk._on_confirm_policy()` sends the selected policies and current state into `MacroEngine.calculate_result()`.
4. `MacroEngine` routes IS-LM model scenarios to `ISLMSolver.solve()`; demo scenarios use `MacroEngine.calculate_demo_result()`.
5. Policies affect IS-LM parameters and `Debt` through the existing policy configuration. The model computes the new `Y` and `i`.
6. `ISLMDemandComponents.update_after_policy()` synchronizes `C_value`, `I_value`, `G_value`, and statuses from the settled output and selected-policy signals.
7. `PolicyDesk` rebuilds map-region tooltip data from the visible macro state.
8. `UnifiedMacroMap` displays hover tooltip rows using independent `metric_id`, `display_symbol`, `value_text`, and `status_text`.
9. Reset and level switching reload fresh deep-copied initial state through `GameState`.

Settlement flow is therefore scheme A:

`Policy -> IS-LM A/d/Debt changes -> model computes Y/i -> demand components synchronize to settled Y`

`C/I/G` do not feed back into `Y`; there is no `Y += delta_C + delta_I + delta_G` second pass.

## Initial Scenario Audit

All 11 existing IS-LM levels pass initial residual checks. Closed-economy identity:

`Y = C_value + I_value + G_value`

Tolerance used by the validator: `0.05`.

| Level | Y | C | I | G | C status | I status | G status | Residual | Semantic result |
|---|---:|---:|---:|---:|---|---|---|---:|---|
| consumer_confidence_drop_basic | 100.0 | 54.0 | 23.0 | 23.0 | low | normal | normal | 0.000 | PASS |
| consumer_confidence_drop_training | 100.0 | 54.0 | 23.0 | 23.0 | low | normal | normal | 0.000 | PASS |
| investment_confidence_drop_basic | 97.0 | 59.7 | 17.5 | 19.8 | normal | low | normal | 0.000 | PASS |
| investment_confidence_drop_training | 97.0 | 59.7 | 17.5 | 19.8 | normal | low | normal | 0.000 | PASS |
| money_market_tightening_basic | 97.6 | 60.0 | 17.6 | 20.0 | normal | low | normal | 0.000 | PASS |
| money_market_tightening_training | 97.6 | 60.0 | 17.6 | 20.0 | normal | low | normal | 0.000 | PASS |
| overheating_and_cooling_basic | 114.0 | 68.4 | 22.8 | 22.8 | high | high | high | 0.000 | PASS |
| overheating_and_cooling_training | 114.0 | 68.4 | 22.8 | 22.8 | high | high | high | 0.000 | PASS |
| fiscal_expansion_crowding_out_training | 113.0 | 67.8 | 20.3 | 24.9 | normal | low | high | 0.000 | PASS |
| double_shock_investment_and_money_demand_training | 94.0 | 57.8 | 16.9 | 19.3 | normal | low | normal | 0.000 | PASS |
| two_round_stabilization_challenge_training | 100.0 | 57.8 | 19.3 | 22.9 | low | low | normal | 0.000 | PASS |

## Meaning Of `Y = 100`

`Y = 100` is not treated as the universal normal output level in these scenarios. In the checked IS-LM scenario configuration, score targets and model parameters commonly use `Y_target` or `Y_potential` around `110`. For demand-weak scenarios such as consumer confidence decline, `Y = 100` is interpreted as the current post-shock output level below the reference target.

The consumer confidence decline levels are self-consistent under that interpretation:

- `C_value = 54.0` is low and matches the narrative shock.
- `I_value = 23.0` and `G_value = 23.0` remain within the normal status band used by the teaching decomposition.
- `Y = 100.0` remains below the target/potential reference, so the weak-demand story is not contradicted.

## Policy Settlement Audit

The validator checked 38 scenario-policy combinations. All passed:

- No settlement produced a residual outside tolerance after synchronization.
- No checked policy showed evidence of a double-applied delta.
- Demo and model settlement paths both route through one demand-component synchronization step.
- `Debt` remains governed by the existing policy/model result; `ISLMDemandComponents` does not rewrite it.

Representative traces:

| Level | Policy | Delta Y | Delta C | Delta I | Delta G | Delta Debt | Residual after |
|---|---|---:|---:|---:|---:|---:|---:|
| consumer_confidence_drop_basic | increase_government_purchase | 2.00 | 2.10 | 0.50 | -0.60 | 2.00 | 0.000 |
| consumer_confidence_drop_basic | expansionary_monetary_policy | 2.00 | 2.10 | -0.60 | 0.50 | 0.00 | 0.000 |
| consumer_confidence_drop_basic | tax_cut | 1.00 | 6.60 | -2.80 | -2.80 | 1.00 | 0.000 |
| fiscal_expansion_crowding_out_training | expansionary_monetary_policy | 3.60 | 0.40 | 2.40 | 0.80 | 0.00 | -0.000 |
| fiscal_expansion_crowding_out_training | contractionary_fiscal_policy | -4.50 | 1.60 | -0.80 | -5.30 | -1.00 | 0.000 |
| fiscal_expansion_crowding_out_training | contractionary_monetary_policy | -3.00 | -1.80 | -0.50 | -0.70 | 0.00 | 0.000 |
| two_round_stabilization_challenge_training | increase_government_purchase | 6.10 | 3.20 | 1.00 | 1.90 | 3.00 | 0.000 |
| two_round_stabilization_challenge_training | expansionary_monetary_policy | 3.60 | -1.90 | 4.50 | 1.00 | 0.00 | 0.000 |
| two_round_stabilization_challenge_training | contractionary_fiscal_policy | -4.50 | -0.50 | -0.20 | -3.80 | -1.00 | 0.000 |

## Reset And Isolation

All 11 levels pass reload/reset checks:

- Initial state reload is stable.
- `current_state` is deep-copied from scenario data.
- No static scenario config mutation was detected.
- Basic/training levels with identical C/I/G values are data-equivalent, not shared mutable state.
- The two-round stabilization challenge carries the round-one after-state into round two, then complete reset restores the original initial state.

## Tooltip Synchronization

The tooltip row structure remains:

- `metric_id`
- `display_symbol`
- `value_text`
- `status_text`

The audit found one UI synchronization risk: after confirming a policy, `PolicyDesk` refreshed the right macro panel from the result state, while the `UnifiedMacroMap` region data could remain on its pre-policy snapshot. This was fixed by calling `_refresh_unified_macro_map(after)` when `_show_policy_result_panel()` receives a valid after-state.

This is a UI data refresh fix only. It does not change model output, policy effects, demand component values, hover animation, alpha masks, or tooltip visual layout.

## Validation Script

Script: `scripts/tools/ValidateDemandComponentSettlement.gd`

Result:

- IS-LM scenarios checked: 11
- Scenario-policy combinations checked: 38
- PASS: 62
- WARN: 0
- FAIL: 0

## Known Remaining Issues

- The validator confirms model/state consistency, not full visual hover interaction in every browser environment.
- Legacy qualitative `C`, `I`, and `G` fields are retained for compatibility; numeric UI should continue to prefer `C_value`, `I_value`, and `G_value`.
- The font export artifact `assets/fonts/NotoSansSC-Regular.ttf` may be touched by the standard export flow and should not be included unless font work is intentional.
