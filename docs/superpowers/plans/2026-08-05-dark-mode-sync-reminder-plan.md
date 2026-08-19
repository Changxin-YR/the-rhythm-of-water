# Dark Mode, Data Sync, and Reminder Reliability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all app surfaces and system bars theme-aware, refresh record-derived data immediately, make reminders reliably diagnosable, and remove the unused cup-management UI without clearing stored cup data.

**Architecture:** Keep palette decisions and refresh revision generation in pure ArkTS helpers covered by Hypium tests. Let `MainPage` resolve and apply theme chrome, individual pages consume semantic theme tokens, and record mutation points publish a single AppStorage revision. Keep reminder persistence in `PreferencesService`, while `ReminderService` returns explicit scheduling diagnostics to `ReminderSettingsPage`.

**Tech Stack:** OpenHarmony ArkTS, ArkUI, Preferences, Reminder Agent, Hypium, Hvigor.

---

## File Map

- Create: `entry/src/main/ets/common/DataRefresh.ets` for the shared refresh revision publisher and pure revision helper.
- Create: `entry/src/main/ets/common/SystemBarAppearance.ets` if needed to isolate pure resolved system-bar colors and icon contrast.
- Create: `entry/src/main/ets/services/SystemBarService.ets` for applying system-bar properties to the active window.
- Modify: `entry/src/main/ets/common/Theme.ets` for complete semantic light/dark tokens.
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets` and `entry/src/main/ets/pages/MainPage.ets` for system-bar lifecycle application.
- Modify: theme-consuming pages and components under `entry/src/main/ets/pages` and `entry/src/main/ets/components` to replace fixed neutral colors with semantic values.
- Modify: `entry/src/main/ets/pages/HomePage.ets` and `entry/src/main/ets/pages/RecordDetailPage.ets` to publish data changes after record mutations.
- Modify: `entry/src/main/ets/services/ReminderService.ets` and `entry/src/main/ets/pages/ReminderSettingsPage.ets` for permission-aware, diagnostic scheduling.
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`, `entry/src/main/ets/common/Routes.ets`, and `entry/src/main/resources/base/profile/main_pages.json` to remove cup management.
- Delete: `entry/src/main/ets/pages/CupPage.ets`.
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets` for pure behavior regression tests.

### Task 1: Establish semantic theme behavior with failing tests

**Files:**
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`
- Modify: `entry/src/main/ets/common/Theme.ets`

- [ ] **Step 1: Write failing palette assertions.**

Add the exact imports and assertions:

```ts
import { getThemeColors } from '../../../main/ets/common/Theme'

it('usesDarkSemanticSurfacesWithoutLightFallbacks', 0, (): void => {
  const colors = getThemeColors(true, 'blue')
  expect(colors.card).assertEqual('#1B2838')
  expect(colors.input).assertEqual('#243447')
  expect(colors.divider).assertEqual('#3A4B5C')
  expect(colors.systemBar).assertEqual('#0D1B2A')
})

it('usesLightSemanticSurfacesWithoutDarkFallbacks', 0, (): void => {
  const colors = getThemeColors(false, 'blue')
  expect(colors.card).assertEqual('#FFFFFF')
  expect(colors.input).assertEqual('#F0F4F7')
  expect(colors.divider).assertEqual('#DDE6ED')
  expect(colors.systemBar).assertEqual('#F4FAFF')
})
```

- [ ] **Step 2: Run the unit test task and observe the expected missing-token failure.**

Run the project-supported Hvigor test task. If a wrapper is unavailable, invoke the installed Hvigor CLI through the local OpenHarmony toolchain. Expected result: the test source fails because `input`, `divider`, and `systemBar` do not yet exist on `ThemeColors`.

- [ ] **Step 3: Add semantic theme fields and values.**

Extend `ThemeColors` with these values and set them in both base palettes:

```ts
input: string
divider: string
progressTrack: string
selectedSurface: string
positiveSurface: string
danger: string
dialogOverlay: string
systemBar: string
systemBarContent: string
```

Use the planned dark values `#243447`, `#3A4B5C`, `#425466`, `#163A52`, `#213A2C`, `#FF8A80`, `#99000000`, `#0D1B2A`, and `#E8F0F8`; set visually equivalent high-contrast light values. Preserve theme-color overrides for `primary`, `primaryDark`, `secondary`, and `accent` only.

- [ ] **Step 4: Re-run the unit test task and verify the palette assertions pass.**

Expected result: the new tests and all existing tests pass.

### Task 2: Move shared and page-local UI surfaces onto theme tokens

**Files:**
- Modify: `entry/src/main/ets/components/GlassCard.ets`
- Modify: `entry/src/main/ets/components/AmountInputDialog.ets`
- Modify: `entry/src/main/ets/components/AchievementCard.ets`
- Modify: `entry/src/main/ets/components/BeverageSelector.ets`
- Modify: `entry/src/main/ets/components/DrinkRecordItem.ets`
- Modify: `entry/src/main/ets/components/HeatmapCalendar.ets`
- Modify: `entry/src/main/ets/components/PlantView.ets`
- Modify: `entry/src/main/ets/components/SegmentedControl.ets`
- Modify: `entry/src/main/ets/components/StatsBarChart.ets`
- Modify: `entry/src/main/ets/components/WaterWaveProgress.ets`
- Modify: affected pages in `entry/src/main/ets/pages`, including Home, Stats, Achievement, Beverage, PlantGarden, DataManage, GoalSettings, Onboarding, Profile, RecordDetail, and Settings.

- [ ] **Step 1: Write a failing component contract test for the dialog palette.**

Add a pure helper in `Theme.ets` if required to expose a serializable dialog palette. Test that the dark dialog input is not `#F0F0F0`, the dark card is not `#FFFFFF`, and the divider/track values differ from their light values. Do not use UI mocks.

- [ ] **Step 2: Run the test and verify it fails because the palette contract is absent.**

Expected result: the new helper/import is missing or the current fixed values violate the expected dark values.

- [ ] **Step 3: Convert shared components before pages.**

Change `GlassCard` so callers pass `cardBackground`, `borderColor`, and shadow values resolved from the current palette. Extend dialog and visual component props with the semantic colors they render. Replace neutral fixed values such as `#FFFFFF`, `#F5F7F8`, `#EDF1F4`, and `#E0E0E0` with those props.

- [ ] **Step 4: Convert pages and dialog controller construction.**

Pass semantic colors from each page's `themeColors` to cards and child components. Recreate or update the Home custom dialog controller after `loadTheme()` so the amount-input dialog receives the current dark/light values. Ensure form inputs, selected tiles, dividers, disabled tracks, call-to-action surfaces, and destructive labels maintain readable contrast.

- [ ] **Step 5: Run static neutral-color audit and unit tests.**

Run:

```powershell
rg -n "#FFFFFF|#F5F7F8|#EDF1F4|#E0E0E0|#F0F0F0" entry/src/main/ets/pages entry/src/main/ets/components
```

Expected result: no unapproved neutral surface fallback remains in a theme-consuming UI path; any intentional transparent overlay is documented inline. Then run the full unit test task successfully.

### Task 3: Apply the resolved theme to status and navigation bars

**Files:**
- Create: `entry/src/main/ets/services/SystemBarService.ets`
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`
- Modify: `entry/src/main/ets/pages/MainPage.ets`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: Write a failing pure appearance test.**

Add a small pure resolver test which asserts dark mode yields a dark bar plus light icons and light mode yields a light bar plus dark icons. Keep the window API outside the test.

- [ ] **Step 2: Run it and confirm the resolver is unavailable.**

Expected result: the test fails for the missing resolver/export.

- [ ] **Step 3: Implement the resolver and window adapter.**

Add a pure `resolveSystemBarAppearance(colors)` function returning background and icon-content colors. Have `SystemBarService` apply those fields via the OpenHarmony `Window` system-bar API. Store or obtain the active main window in `EntryAbility`; invoke the service after content creation and whenever `MainPage.reloadTheme()` resolves a new palette. Catch and log only window-API failures without changing app rendering.

- [ ] **Step 4: Build and perform a focused device check.**

Build the HAP. On device, switch app light/dark settings and OS color mode, then open every root tab plus Beverage, Reminder, PlantGarden, Profile, DataManage, GoalSettings, and RecordDetail. Expected result: status and navigation bars use the app surface and have legible icon contrast; no content overlaps the safe areas.

### Task 4: Publish record mutations to refresh all mounted pages

**Files:**
- Create: `entry/src/main/ets/common/DataRefresh.ets`
- Modify: `entry/src/main/ets/pages/HomePage.ets`
- Modify: `entry/src/main/ets/pages/RecordDetailPage.ets`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: Write failing revision tests.**

```ts
import { nextRefreshRevision } from '../../../main/ets/common/DataRefresh'

it('alwaysChangesTheRefreshRevision', 0, (): void => {
  expect(nextRefreshRevision(0)).assertEqual(1)
  expect(nextRefreshRevision(41)).assertEqual(42)
})
```

- [ ] **Step 2: Run the test and confirm the helper is missing.**

Expected result: test compilation fails for `nextRefreshRevision`.

- [ ] **Step 3: Implement and use the publisher.**

Create `nextRefreshRevision(current: number): number` and `publishDataRefresh()`; the publisher reads the current `refreshSignal` from AppStorage and writes the next revision. Call it only after a successful add, undo, Home deletion, and record-detail deletion, after plant/achievement reconciliation completes.

- [ ] **Step 4: Run tests and verify behavior on device.**

Add a drink, switch immediately to Stats and Achievement, undo it, and delete a record from detail. Expected result: totals, charts, plant progress, and achievement values update before process restart each time.

### Task 5: Separate reminder persistence from schedule publication and diagnose platform failures

**Files:**
- Modify: `entry/src/main/ets/services/ReminderService.ets`
- Modify: `entry/src/main/ets/pages/ReminderSettingsPage.ets`
- Modify: `entry/src/main/ets/common/WaterReminderRules.ets` if a pure result classifier is needed
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: Write failing result-classification tests.**

Define and test a pure classifier with the following expected behavior:

```ts
expect(classifyReminderSchedule(false, 0, 0, '')).assertEqual('disabled')
expect(classifyReminderSchedule(true, 3, 3, '')).assertEqual('published')
expect(classifyReminderSchedule(true, 3, 0, 'permission')).assertEqual('permission_required')
expect(classifyReminderSchedule(true, 3, 0, 'cancel')).assertEqual('schedule_failed')
```

- [ ] **Step 2: Run the test and verify the classifier is missing.**

Expected result: Hypium reports a missing export.

- [ ] **Step 3: Add diagnostic schedule results and permission preflight.**

Extend `ReminderScheduleResult` with a status and user-safe failure message. Preserve the current safe rule that a cancellation failure blocks new publications, but retain the saved configuration and report `schedule_failed` rather than reporting a false preference-save failure. Check the reminder permission before scheduling and request it from the settings UI if the platform marks it ungranted. Log native error code/message for cancellation and each slot publication.

- [ ] **Step 4: Make settings-page feedback truthful.**

After successful preference save, navigate back only for `disabled` or fully `published`. For permission or platform failures, keep the page visible and show a message that distinguishes saved settings from an unpublished schedule. Do not replace a specific platform error with the generic "save failed" toast.

- [ ] **Step 5: Verify red-green and device behavior.**

Run the pure tests, build the HAP, then on device: deny permission once, request it again, save a near-future short interval, reopen settings to verify persistence, and observe the system reminder. Record any device policy block separately from application exceptions.

### Task 6: Remove cup management without deleting persisted cup data

**Files:**
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`
- Modify: `entry/src/main/ets/common/Routes.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Delete: `entry/src/main/ets/pages/CupPage.ets`

- [ ] **Step 1: Search for all reachable cup UI references.**

Run:

```powershell
rg -n "CupPage|Routes\.CUP|杯具管理" entry/src/main/ets entry/src/main/resources
```

Expected result before the change: Settings, routes, page registration, and CupPage are found.

- [ ] **Step 2: Remove only UI reachability.**

Delete the Settings tile, `Routes.CUP`, the `pages/CupPage` registry entry, and `CupPage.ets`. Do not call `removeCup`, clear preferences, or alter the backup model.

- [ ] **Step 3: Verify the route is gone and data storage remains intact.**

Re-run the search. Expected result: no UI route reference remains. Confirm `Constants.PREFERENCES_CUPS`, `PreferencesService` cup serialization, and backup validation are unchanged.

### Task 7: Final full regression and visual verification

**Files:**
- Read: all changed files

- [ ] **Step 1: Run the complete Hypium test task.**

Expected result: zero test failures.

- [ ] **Step 2: Build the debug HAP with Hvigor.**

Use the project-supported debug HAP task. Expected result: process exit code 0 and an installable HAP under `entry/build`.

- [ ] **Step 3: Install and check the regression matrix.**

Check light/dark bars, all dark page text/forms, custom amount dialog, drink add/undo/delete cross-tab refresh, removed cup route, reminder persistence, permission handling, and published reminder observation.

- [ ] **Step 4: Inspect the final workspace.**

Run `rg` audits for stale cup routes and neutral colors. Git commands are not applicable because this directory contains no Git repository. Report fresh test, build, and device evidence; do not claim success without all available checks.
