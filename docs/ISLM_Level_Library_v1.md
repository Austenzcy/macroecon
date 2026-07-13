# IS-LM Level Library v1

## Purpose

This version adds a scalable test entry for the first IS-LM level library. The player can enter a LevelSelect page from MainMenu and choose one of several short-run closed-economy IS-LM situations.

Each situation currently has two modes:

- Basic teaching: `selection_mode = single`, `settlement_mode = demo`
- Combination training: `selection_mode = budget`, `settlement_mode = model`

## Level Groups

The first batch contains four IS-LM situations:

1. Consumer confidence drop
   - Shock: consumption willingness falls, `C` decreases.
   - Model direction: IS shifts left.
   - Goal: stabilize weak demand.

2. Investment confidence drop
   - Shock: firms postpone investment, `I` decreases.
   - Model direction: IS shifts left.
   - Goal: compare fiscal support and monetary easing.

3. Money demand rise
   - Shock: liquidity preference rises.
   - Model direction: LM shifts left/up.
   - Goal: observe how money market pressure affects interest rates and output.

4. Government spending expansion
   - Shock: public spending rises sharply.
   - Model direction: IS shifts right.
   - Goal: practice cooling overheated demand with contractionary or wait-and-see choices.

## Scenario Structure

`data/scenarios.json` now stores eight scenario entries:

- Four basic teaching scenarios
- Four combination training scenarios

Training scenarios include `model_params.IS_LM`, so `ISLMSolver` can solve each level from JSON configuration rather than hardcoded values.

Training scenarios also include `score_config`. `ScoreEngine` reads this configuration when present; missing or disabled score configuration should not crash the game.

## Policy Cards

`data/policies.json` now includes six policy cards:

- Increase government purchases
- Expansionary monetary policy
- Tax cut
- Contractionary fiscal policy
- Contractionary monetary policy
- Keep policy unchanged

Policy cards describe model parameter impacts through `policy_impacts.IS_LM`, such as `delta_A`, `delta_d`, and `debt_delta`. They do not store final output or interest-rate results.

## Current Limits

- This library only covers IS-LM situations.
- AD-AS, Mundell-Fleming, and Solow level libraries are not implemented yet.
- LevelSelect is a test-entry page, not a full campaign map.
- There is no tutorial guide, event system, or variable chart system in this version.
