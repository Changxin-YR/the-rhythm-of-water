# HarmonyOS Compliance Touch, Data, and Audit Repair Design

**Date:** 2026-08-12

**Project:** `C:\Users\27363\Desktop\APP\WaterReminder`

## Goal

Resolve the confirmed HarmonyOS compliance gaps that can be fixed locally without adding the AppGallery privacy-policy materials that the developer will provide before submission.

## Scope

This repair covers:

1. Huawei UX requirement `2.1.3.3`: every directly clickable phone/tablet control must expose a hit area of at least `40vp x 40vp`. The implementation will use the recommended `48vp` target where layout permits and the mandatory `40vp` minimum for dense controls.
2. Data minimization: remove `age`, `gender`, and `heightCm` from active profile collection because no application behavior uses them. Keep `weightKg`, `activityLevel`, `specialState`, and `climate` because they affect the hydration-goal calculation.
3. Backward compatibility: continue reading existing profiles and backups that contain the removed fields. New saves and new backups will omit them.
4. Audit reliability: replace reminder-specific and protocol-section-number assertions with checks that reflect the current product behavior.
5. Evidence: rerun the static contracts, Hypium tests, release build, and connected-phone runtime checks, then write a requirement-level audit report.

The following items are explicitly deferred at the developer's request:

- In-app standalone privacy-policy page.
- First-use privacy consent and refusal flow.
- Public privacy-policy URL in AppGallery Connect.
- AppGallery privacy labels and filing/qualification materials.

They must remain `unverified` or `partial` in the final audit and must be completed before submission. The audit will not claim privacy compliance from the local-data-only implementation.

## Approach

### Interaction Targets

Introduce shared interaction-size tokens so compliance is expressed once instead of repeated as unrelated literals:

- Recommended target: `48vp`.
- Dense minimum target: `40vp`.

Apply these tokens to directly clickable controls found below the mandatory threshold, including segmented options, amount presets, profile choice chips, beverage icons and delete actions, and ledger category icon/color/delete controls. Preserve the visual glyph or swatch size by centering it inside the larger hit box when increasing the visible element would make the interface visually heavy.

Existing controls already at or above the threshold, such as bottom navigation items, 44vp page-header buttons, 48vp primary buttons, category tiles, and number-keyboard keys, will not be changed.

### Profile Data Minimization

Remove `age`, `gender`, and `heightCm` from `UserProfile`, `DEFAULT_PROFILE`, cloning logic, onboarding controls, and profile editing controls. The goal calculator remains unchanged because it currently receives only weight, activity, special state, and climate.

Stored JSON and imported backup JSON may contain extra legacy keys. Validation will continue to accept those payloads while requiring the current fields, and normalization will return only the current profile shape. This provides a read-compatible, write-clean migration without a destructive database or preferences migration.

The onboarding flow will retain the same three-step structure:

1. Welcome and usage context.
2. Nickname, weight, and activity level.
3. Calculated hydration goal.

### Audit Contracts

Update `tools/verify_harmony_review_checklist.ps1` so notification/reminder checks are conditional on the feature actually existing. Since the current product contains no notification/reminder feature or notification permission, notification-specific UX requirement `2.2.2` is `not applicable`.

Update `tools/verify_ui_repair_contract.ps1` to verify a protocol-change section by its title rather than a hard-coded chapter number. Add checks for the interaction-size tokens, the known dense controls, and absence of active collection for removed profile fields.

## Testing

Follow red-green testing for each behavior change:

1. Add Hypium tests defining the minimized current profile shape and proving legacy profile payloads still normalize successfully.
2. Add or extend a PowerShell contract that fails against the current undersized controls and stale audit assertions.
3. Run each new test before implementation and confirm the expected failure.
4. Make the smallest production changes required for the tests to pass.
5. Run all static contracts and the full Hypium suite.
6. Build the release HAP and inspect compiler output without hiding existing warnings.
7. Install the release HAP on the connected API 22 phone emulator and capture representative light/dark screenshots and layout evidence for system bars, bottom navigation, and repaired controls.

Tablet, landscape, split-screen, floating-window, AppAnalyzer latency, live official-source recheck, and AppGallery Connect metadata remain `unverified` unless those environments become available during verification.

## Acceptance Criteria

- No known directly clickable phone/tablet control has a source-defined hit area below `40vp x 40vp`.
- Shared tokens preserve the official distinction between the `48vp` recommendation and `40vp` mandatory minimum.
- The UI no longer asks for or displays age, gender, or height.
- Existing saved profiles and backups containing those legacy fields remain readable.
- Newly normalized and saved profiles omit the removed fields.
- Both previously stale audit failures are replaced by assertions matching the current feature set.
- Static contracts, Hypium tests, and release build are rerun with fresh results.
- The final audit uses only `pass`, `fail`, `partial`, `not applicable`, or `unverified`, and explicitly records the deferred privacy work.

## Repository Note

This workspace does not expose Git metadata, so the design cannot be committed. Verification checkpoints and artifact paths will be recorded instead.
