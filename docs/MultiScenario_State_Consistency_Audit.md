# Multi-Scenario State Consistency Audit

## Scope

This audit checks state flow and text sources across multiple IS-LM scenarios and the two-round prototype.

The goal is consistency, not new gameplay:

- No new model families
- No new scoring formulas
- No new event system
- No basic-level scoring
- No CloudBase script changes

## Findings And Fixes

### Round 2 Before State

Finding:

`ISLMSolver` rebuilt each round from `scenario.model_params.IS_LM`, so the second round could display a `before` state that looked like the original scenario state rather than the previous round's `after`.

Fix:

`ISLMSolver` now stores internal IS-LM state keys in `result.after`:

- `_islm_A`
- `_islm_b`
- `_islm_c`
- `_islm_d`

When the next round starts, `GameState.current_state` inherits `result.after`, so the solver reads these model-state keys and uses the previous round's equilibrium as the next round's starting point.

### Right-Side Policy Result Panel

Finding:

The right-side panel should use one result object for both values and arrows. Any mismatch between displayed values and arrows would make the current round state ambiguous.

Fix:

The policy result panel reads displayed values from `result.after` and arrow direction from `result.before` versus `result.after`. It does not read `GameState.current_state` for post-policy values.

`π` / `蟺` compatibility was also tightened in result display helpers.

### FinalSummary Learning Text

Finding:

`FinalSummary` contained a hardcoded consumer-confidence learning point, so non-consumer scenarios could still show "消费信心下降导致 C 下降".

Fix:

Each scenario now has `learning_points`. `FinalSummary` reads learning points from the current scenario. If a scenario lacks this field later, it falls back to `model_hint` or `problem_title`.

### Conditional Combination Policy Tip

Finding:

The final summary always showed the "combine parameters, then solve equilibrium" tip.

Fix:

`FinalSummary` now adds that tip only when at least one round has two or more selected policies in `round_history`.

## Data Source Rules

- Current scenario content comes from `GameState.get_current_scenario()`.
- Current round result pages read from `GameState.last_result`.
- Right-side post-policy state reads from the current round result.
- FinalSummary reads history from `GameState.round_history`.
- The next round starts from the previous round's `result.after`.

## Notes

Basic teaching scenarios still use demo settlement and do not enable scoring. ScoreEngine continues to read `scenario.score_config`; missing or disabled config produces a safe fallback.
