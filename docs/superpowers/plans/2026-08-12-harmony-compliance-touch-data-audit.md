# HarmonyOS Compliance Touch and Data Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove unused personal-profile fields, repair undersized interaction targets, align the audit scripts with the current product, and produce fresh HarmonyOS verification evidence.

**Architecture:** Keep profile compatibility in the existing `UserProfile` normalization and backup-validation boundary, and keep presentation changes local to the ArkUI components that own each hit area. Express Huawei's `48vp` recommendation and `40vp` mandatory minimum through shared UI tokens, then enforce the known contract with Hypium behavior tests plus source-level PowerShell checks.

**Tech Stack:** ArkTS, ArkUI, Hypium, Hvigor, HDC, PowerShell, HarmonyOS API 22 emulator.

---

### Task 1: Define Profile Minimization and Legacy Compatibility

**Files:**
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`
- Modify: `entry/src/main/ets/models/UserProfile.ets`
- Modify: `entry/src/main/ets/common/BackupRules.ets`
- Modify: `entry/src/main/ets/services/PreferencesService.ets`
- Modify: `entry/src/main/ets/services/DemoDataService.ets`
- Modify: `entry/src/main/ets/pages/OnboardingPage.ets`
- Modify: `entry/src/main/ets/pages/ProfilePage.ets`

- [ ] **Step 1: Add failing profile-minimization tests**

Add tests that construct the current profile without `age`, `gender`, or `heightCm`, assert that `validateUserProfileJson()` accepts it, assert that a legacy JSON object containing those extra keys is accepted, and assert that `JSON.stringify(cloneUserProfile(legacyProfile))` omits all three legacy keys.

```ts
it('acceptsCurrentAndLegacyProfilesButNormalizesUnusedFieldsAway', 0, (): void => {
  const currentProfile: UserProfile = {
    nickname: '测试用户', avatarId: DEFAULT_AVATAR_ID,
    weightKg: 60, activityLevel: 'light', specialState: 'none', climate: 'normal',
    dailyGoalMl: 2200, isGoalAutoCalculated: true, onboardingCompleted: true,
    createdAt: 1, updatedAt: 2
  }
  expect(validateUserProfileJson(JSON.stringify(currentProfile))).assertTrue()

  const legacyJson = JSON.stringify({
    ...currentProfile, age: 25, gender: 'male', heightCm: 170
  })
  expect(validateUserProfileJson(legacyJson)).assertTrue()

  const normalized = JSON.stringify(cloneUserProfile(JSON.parse(legacyJson) as UserProfile))
  expect(normalized.includes('"age"')).assertFalse()
  expect(normalized.includes('"gender"')).assertFalse()
  expect(normalized.includes('"heightCm"')).assertFalse()
})
```

- [ ] **Step 2: Build and run the Hypium suite to verify RED**

Run:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@ohosTest -p product=default --no-daemon
```

Expected: type-check failure because the current `UserProfile` still requires the three fields, or a test failure because normalization still preserves/requires them.

- [ ] **Step 3: Minimize the active profile model**

Change `UserProfile` and `DEFAULT_PROFILE` to retain only:

```ts
nickname: string
avatarId: string
weightKg: number
activityLevel: ActivityLevel
specialState: SpecialState
climate: ClimateType
dailyGoalMl: number
isGoalAutoCalculated: boolean
onboardingCompleted: boolean
createdAt: number
updatedAt: number
```

Update `cloneUserProfile()` to construct exactly that shape. In `PreferencesService.saveProfile()`, serialize `cloneUserProfile(profile)` so imported legacy objects are written back without extra keys.

- [ ] **Step 4: Make validation read-compatible and write-clean**

Update `isValidUserProfile()` so it requires the current fields and ignores extra legacy keys. Remove the old-field requirements. Keep malformed or incomplete current profiles rejected.

- [ ] **Step 5: Remove unused collection and display controls**

Remove age and gender from onboarding. Remove age, gender, and height from profile editing. Remove obsolete imports and update `DemoDataService` profile copies to the current shape. Do not change the hydration-goal formula or fields that feed it.

- [ ] **Step 6: Build, install, and run Hypium to verify GREEN**

Run the ohosTest build, install `entry-ohosTest-signed.hap`, and execute `OpenHarmonyTestRunner`.

Expected: all tests pass with zero failures and zero errors.

### Task 2: Establish the Interaction-Target Contract

**Files:**
- Modify: `entry/src/main/ets/common/Theme.ets`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`
- Modify: `tools/verify_harmony_review_checklist.ps1`

- [ ] **Step 1: Add a failing token test**

Extend the UI-token test with:

```ts
expect(UiTokens.recommendedTouchTargetSize).assertEqual(48)
expect(UiTokens.minimumTouchTargetSize).assertEqual(40)
```

- [ ] **Step 2: Add failing source-contract checks for known dense controls**

Extend `verify_harmony_review_checklist.ps1` to require the shared tokens and their use in:

- `SegmentedControl.ets`
- `AmountInputDialog.ets`
- `WaterHubPage.ets`
- `BeveragePage.ets`
- `OnboardingPage.ets`
- `ProfilePage.ets`
- `LedgerCategoryManagePage.ets`

The checks must verify the interactive container, not the glyph or color swatch, has at least the shared minimum target.

- [ ] **Step 3: Run both checks to verify RED**

Run the ohosTest build and:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_harmony_review_checklist.ps1
```

Expected: failure because the tokens and repaired hit boxes do not exist yet.

- [ ] **Step 4: Add the official interaction tokens**

Add to `UiTokenValues` and `UiTokens`:

```ts
recommendedTouchTargetSize: 48
minimumTouchTargetSize: 40
```

Use names that preserve the official distinction: `48vp` is recommended; `40vp` is mandatory minimum.

### Task 3: Repair Shared and Water-Feature Hit Areas

**Files:**
- Modify: `entry/src/main/ets/components/SegmentedControl.ets`
- Modify: `entry/src/main/ets/components/AmountInputDialog.ets`
- Modify: `entry/src/main/ets/pages/WaterHubPage.ets`
- Modify: `entry/src/main/ets/pages/BeveragePage.ets`

- [ ] **Step 1: Repair shared compact controls**

Set segmented options to `UiTokens.minimumTouchTargetSize` height and their track to at least `44vp`. Wrap or size each amount preset to at least `UiTokens.minimumTouchTargetSize` in both dimensions while keeping the existing visual style.

- [ ] **Step 2: Repair water-page text actions**

Give the `统计` and `成就` actions a `UiTokens.minimumTouchTargetSize` minimum height. Keep the title row height stable.

- [ ] **Step 3: Repair beverage actions**

Give beverage icon choices and custom-delete actions at least `UiTokens.minimumTouchTargetSize` hit boxes. Preserve the current icon glyph sizes inside those boxes.

- [ ] **Step 4: Run the static audit checkpoint**

Run `verify_harmony_review_checklist.ps1`.

Expected: shared/water target checks pass; any remaining failures are limited to profile/ledger controls or stale audit assertions.

### Task 4: Repair Profile and Ledger Hit Areas

**Files:**
- Modify: `entry/src/main/ets/pages/OnboardingPage.ets`
- Modify: `entry/src/main/ets/pages/ProfilePage.ets`
- Modify: `entry/src/main/ets/ledger/pages/LedgerCategoryManagePage.ets`

- [ ] **Step 1: Repair onboarding and profile choices**

Set every directly clickable activity, special-state, and climate choice to a minimum height of `UiTokens.minimumTouchTargetSize`. Give compact header text actions an explicit minimum hit box where their padding does not prove the threshold.

- [ ] **Step 2: Repair ledger category controls**

Use the shared minimum size for the add action, expense/income tabs, custom delete action, icon choices, and color-choice containers. Keep color circles at their current visible size inside a `40vp` container.

- [ ] **Step 3: Run the interaction audit to verify GREEN**

Run `verify_harmony_review_checklist.ps1`.

Expected: every interaction-target assertion passes; only stale product-contract assertions may remain until Task 5.

### Task 5: Align Audit Scripts With the Current Product

**Files:**
- Modify: `tools/verify_harmony_review_checklist.ps1`
- Modify: `tools/verify_ui_repair_contract.ps1`

- [ ] **Step 1: Replace the obsolete reminder assertion**

Detect whether notification/reminder production code or notification permission exists. When absent, pass the check as not applicable. When present, require a non-misleading failure message and the corresponding permission/configuration checks.

- [ ] **Step 2: Replace the hard-coded protocol chapter number**

Assert the presence of a `协议变更` card without assuming it must be chapter seven.

- [ ] **Step 3: Run all source contracts**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_harmony_review_checklist.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_ui_repair_contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_scroll_content_top_alignment.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_reset_all_data_contract.ps1
```

Expected: all scripts exit `0`.

### Task 6: Build, Exercise, and Report

**Files:**
- Create: `docs/harmony-self-check-2026-08-12.md`
- Create: `device-evidence/harmony-audit-*-2026-08-12.png`
- Create: `device-evidence/harmony-audit-*-2026-08-12.json`

- [ ] **Step 1: Run the complete Hypium suite**

Rebuild and install the ohosTest HAP, then run `OpenHarmonyTestRunner`.

Expected: zero failures and zero errors; record the exact test count.

- [ ] **Step 2: Build the release HAP**

Run:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=release --no-daemon
```

Expected: exit `0`. Record warnings separately; do not describe a warning-bearing build as pristine.

- [ ] **Step 3: Install and exercise the release package**

Install `entry-default-signed.hap`, cold-launch it, and inspect representative light/dark screens. Exercise the repaired compact controls, system Back, status bar, bottom navigation, scroll end, and at least one dialog/input state. Capture screenshots and layout/bounds where the emulator exposes them.

- [ ] **Step 4: Write the requirement-level report**

Create one row per applicable Huawei UX requirement and relevant AppGallery policy section with columns:

```markdown
| ID | Level | Devices | Applicability | Evidence | Verdict | Gap / remediation |
```

Use only `pass`, `fail`, `partial`, `not applicable`, or `unverified`. Mark privacy policy/consent/AGC metadata, tablet, landscape, split/floating windows, performance timing, classification, filing, and qualifications accurately as deferred or unverified.

- [ ] **Step 5: Run final verification from a clean command invocation**

Rerun all four PowerShell contracts, the complete Hypium suite, and the release build. Read exit codes and failure counts before making any completion claim.

## Repository Note

This directory has no `.git` metadata. Commit steps are intentionally replaced by explicit verification checkpoints and evidence artifacts.
