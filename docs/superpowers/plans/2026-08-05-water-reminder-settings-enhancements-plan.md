# Water Reminder Settings Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make page switching click-only, add persistent built-in avatar selection, give reminder modes different system behavior, and hide the progress indicator when it overlaps the water drop.

**Architecture:** Keep all device-independent decisions in pure ArkTS helpers tested by the existing Hypium suite. Keep system reminder construction in `ReminderService`, profile persistence in `PreferencesService`, and UI changes inside the existing pages/components. Replace the swipe-capable root `Tabs` with a `Stack` and explicit bottom navigation so vertical page scrolling remains available without horizontal page paging.

**Tech Stack:** OpenHarmony ArkTS, ArkUI, `@kit.BackgroundTasksKit` Reminder Agent, Preferences, Hypium, Hvigor.

---

## File Map

- Create: `entry/src/main/ets/common/AvatarOptions.ets` for the stable built-in avatar catalog and fallback lookup.
- Modify: `entry/src/main/ets/models/UserProfile.ets` for `avatarId` and backward-compatible cloning.
- Modify: `entry/src/main/ets/common/BackupRules.ets` to accept an omitted legacy avatar field and reject unknown non-empty IDs.
- Modify: `entry/src/main/ets/common/WaterReminderRules.ets` for reminder-mode options and progress-indicator overlap calculation.
- Modify: `entry/src/main/ets/services/ReminderService.ets` to map mode options to the system request and return a schedule result.
- Modify: `entry/src/main/ets/pages/MainPage.ets` to remove `Tabs` swipe paging and render click-only navigation.
- Modify: `entry/src/main/ets/components/WaterWaveProgress.ets` to suppress the Gauge indicator only in the overlap state.
- Modify: `entry/src/main/ets/pages/ProfilePage.ets` to show and choose built-in avatars.
- Modify: `entry/src/main/ets/pages/SettingsPage.ets` to render the persisted avatar on the profile card.
- Modify: `entry/src/main/ets/pages/ReminderSettingsPage.ets` to surface scheduling failures and keep the two mode descriptions visible.
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets` for pure rule regression coverage and any required profile fixtures.

### Task 1: Lock down pure behavior with failing tests

**Files:**
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`
- Create: `entry/src/main/ets/common/AvatarOptions.ets`
- Modify: `entry/src/main/ets/common/WaterReminderRules.ets`

- [ ] **Step 1: Add failing assertions for avatar fallback, reminder mode options, and indicator overlap.**

Add imports and tests with these expected APIs:

```ts
import { DEFAULT_AVATAR_ID, normalizeAvatarId } from '../../../main/ets/common/AvatarOptions'
import { getReminderModeOptions, shouldHideProgressIndicator } from '../../../main/ets/common/WaterReminderRules'

it('fallsBackToDefaultAvatarForMissingOrUnknownIds', 0, (): void => {
  expect(normalizeAvatarId('avatar_sun')).assertEqual('avatar_sun')
  expect(normalizeAvatarId('')).assertEqual(DEFAULT_AVATAR_ID)
  expect(normalizeAvatarId('removed_avatar')).assertEqual(DEFAULT_AVATAR_ID)
})

it('usesQuietOptionsForGentleReminders', 0, (): void => {
  const options = getReminderModeOptions('gentle')
  expect(options.ringDuration).assertEqual(0)
  expect(options.snoozeTimes).assertEqual(0)
  expect(options.showActionButton).assertFalse()
})

it('usesAlarmOptionsForActiveReminders', 0, (): void => {
  const options = getReminderModeOptions('active')
  expect(options.ringDuration).assertEqual(5)
  expect(options.snoozeTimes).assertEqual(1)
  expect(options.showActionButton).assertTrue()
})

it('hidesProgressIndicatorOnlyNearWaterDropAnchor', 0, (): void => {
  expect(shouldHideProgressIndicator(100)).assertTrue()
  expect(shouldHideProgressIndicator(98)).assertTrue()
  expect(shouldHideProgressIndicator(86)).assertFalse()
})
```

- [ ] **Step 2: Run the existing Hypium test task and verify the new tests fail for missing exports.**

Run `hvigorw test`. If this project exposes the task through the installed Hvigor CLI instead of a wrapper, run the equivalent `test` task from the project root. Expected result: failure mentioning the missing avatar or rule exports; do not change production UI code to make this test pass.

- [ ] **Step 3: Add the minimal pure interfaces and functions.**

Create `AvatarOptions.ets` with a stable list and fallback:

```ts
export interface AvatarOption {
  id: string
  glyph: string
}

export const DEFAULT_AVATAR_ID: string = 'avatar_sun'
export const AVATAR_OPTIONS: AvatarOption[] = [
  { id: 'avatar_sun', glyph: '☀️' },
  { id: 'avatar_cloud', glyph: '☁️' },
  { id: 'avatar_leaf', glyph: '🍃' },
  { id: 'avatar_wave', glyph: '🌊' },
  { id: 'avatar_moon', glyph: '🌙' },
  { id: 'avatar_star', glyph: '⭐' }
]

export function normalizeAvatarId(id: string | undefined): string {
  for (const item of AVATAR_OPTIONS) {
    if (item.id === id) return item.id
  }
  return DEFAULT_AVATAR_ID
}

export function avatarGlyph(id: string | undefined): string {
  const normalized = normalizeAvatarId(id)
  for (const item of AVATAR_OPTIONS) {
    if (item.id === normalized) return item.glyph
  }
  return AVATAR_OPTIONS[0].glyph
}
```

Add to `WaterReminderRules.ets`:

```ts
import { ReminderMode } from '../models/ReminderConfig'

export interface ReminderModeOptions {
  ringDuration: number
  snoozeTimes: number
  timeInterval: number
  showActionButton: boolean
}

export function getReminderModeOptions(mode: ReminderMode): ReminderModeOptions {
  return mode === 'active'
    ? { ringDuration: 5, snoozeTimes: 1, timeInterval: 5 * 60, showActionButton: true }
    : { ringDuration: 0, snoozeTimes: 0, timeInterval: 0, showActionButton: false }
}

export function shouldHideProgressIndicator(progress: number): boolean {
  return Number.isFinite(progress) && progress >= 98
}
```

- [ ] **Step 4: Run the same test task and verify the pure tests pass.**

Run `hvigorw test`. Expected result: the new assertions and all existing `WaterReminderRules` assertions pass.

### Task 2: Persist avatars without breaking old profiles

**Files:**
- Modify: `entry/src/main/ets/models/UserProfile.ets`
- Modify: `entry/src/main/ets/common/BackupRules.ets`
- Modify: `entry/src/main/ets/services/PreferencesService.ets` only if normalization is needed at the read boundary
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: Add a regression fixture for a legacy profile without `avatarId`.**

Extend the existing JSON validation tests with a profile object that omits `avatarId` and assert `validateUserProfileJson` accepts it. Add `avatarId: 'avatar_sun'` to all typed `UserProfile` fixtures so the new required field is explicit for current data.

- [ ] **Step 2: Run the test task and verify the new typed fixtures/legacy assertion fail before the model changes.**

Run `hvigorw test`. Expected result: current typed profile fixtures fail to satisfy the new field or the legacy validation assertion fails if it is written as a required field.

- [ ] **Step 3: Add and normalize `avatarId` in the profile model.**

Import `DEFAULT_AVATAR_ID` and `normalizeAvatarId` into `UserProfile.ets`, add `avatarId: string` to `UserProfile`, set `DEFAULT_PROFILE.avatarId` to `DEFAULT_AVATAR_ID`, and make `cloneUserProfile` return `avatarId: normalizeAvatarId(profile.avatarId)`. This makes old parsed objects safe before UI consumption.

- [ ] **Step 4: Keep backup validation backward-compatible.**

Update `isValidUserProfile` so `avatarId` is valid when omitted or when it is one of the built-in IDs. Do not accept arbitrary non-string values:

```ts
const avatarIsValid = profile.avatarId === undefined || isString(profile.avatarId)
return avatarIsValid && isString(profile.nickname) && /* existing checks */
```

The cloning boundary remains responsible for converting unknown strings to the default stable ID.

- [ ] **Step 5: Run the test task and verify current and legacy profiles pass.**

Run `hvigorw test`. Expected result: all profile, backup, and existing water-reminder assertions pass.

### Task 3: Make the two reminder modes effective and observable

**Files:**
- Modify: `entry/src/main/ets/services/ReminderService.ets`
- Modify: `entry/src/main/ets/pages/ReminderSettingsPage.ets`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets` only if service-facing result types need a fixture

- [ ] **Step 1: Add a service result contract before changing scheduling.**

Define:

```ts
export interface ReminderScheduleResult {
  requested: number
  published: number
  failed: number
}
```

Change `scheduleReminders(): Promise<void>` to `Promise<ReminderScheduleResult>` while preserving compatibility for callers that ignore the return value. `createSingleReminder` should return `Promise<boolean>`.

- [ ] **Step 2: Run the test/build task and verify the signature change exposes any callers that assume a different return type.**

Run `hvigorw test` and then the available Hvigor compile task. Expected result: no caller should require `void`; the only required changes should be the service implementation and the save flow.

- [ ] **Step 3: Apply pure mode options to each alarm request.**

In `createSingleReminder`, call `getReminderModeOptions(config.mode)`, set `ringDuration` from the result, and construct the common `ReminderRequestAlarm`. When `showActionButton` is true, set `snoozeTimes`, `timeInterval`, and the existing close button. When false, set `snoozeTimes: 0` and omit `actionButton`; keep the title/content/wantAgent and schedule slot unchanged.

Count each successful `publishReminder` as `published`, each caught publish error as `failed`, and return `{ requested: slots.length, published, failed }`. Log the slot and mode on failures. If cancellation fails, return a failed result rather than claiming success.

- [ ] **Step 4: Surface save errors in `ReminderSettingsPage`.**

Wrap preference save and schedule calls in `try/catch`. After saving, if `result.failed > 0`, show a toast such as `已保存，但有 ${result.failed} 条提醒未发布` and keep the page open; otherwise navigate back. If the user disables reminders, the zero-request successful result should navigate back after old reminders are cancelled.

- [ ] **Step 5: Run the test/build task and verify no regression in reminder slot generation.**

Run `hvigorw test` and the available Hvigor compile task. Expected result: mode helper tests remain green and ArkTS accepts the optional request fields.

### Task 4: Remove horizontal page paging and hide the overlapping indicator

**Files:**
- Modify: `entry/src/main/ets/pages/MainPage.ets`
- Modify: `entry/src/main/ets/components/WaterWaveProgress.ets`

- [ ] **Step 1: Replace `Tabs` with an explicit click-only shell.**

Keep the current `tabItems`, `currentIndex`, colors, and `TabBuilder`. Render a `Column` containing a `Stack` with conditional children:

```ts
Stack() {
  if (this.currentIndex === 0) { HomePage() }
  else if (this.currentIndex === 1) { StatsPage() }
  else if (this.currentIndex === 2) { AchievementPage() }
  else { SettingsPage() }
}
.layoutWeight(1)
```

Below it, render a fixed-height `Row` and call the existing tab builder for each item; each item sets `this.currentIndex`. Remove `Tabs`, `TabContent`, `.barMode`, and the root `.onChange`. Keep page content vertical scrolling untouched.

- [ ] **Step 2: Verify the navigation source has no swipe-capable root.**

Run `rg -n "Tabs|TabContent|Swiper|horizontal" entry/src/main/ets/pages/MainPage.ets`. Expected result: no `Tabs`, `TabContent`, or horizontal pager in `MainPage.ets`.

- [ ] **Step 3: Add the overlap condition to `WaterWaveProgress`.**

Import `shouldHideProgressIndicator`. Compute `const hideIndicator = shouldHideProgressIndicator(this.progress)` and render a `Progress({ value: ..., total: 100, type: ProgressType.Ring })` ring in the hide state so the ring remains visible without Gauge's default black pointer. Render the existing `Gauge` in the non-overlap state, preserving its colors, size, and stroke width. Keep the water-drop text above the ring in both states.

- [ ] **Step 4: Run the compile task and verify ArkUI component types.**

Run the available Hvigor compile/build command. Expected result: `MainPage.ets` compiles with `Stack` conditional content and `WaterWaveProgress.ets` compiles with the SDK's `ProgressType.Ring` API. If the SDK requires ring styling through `.style(...)`, use the SDK declaration in `ets/component/progress.d.ts` and keep the visual values at 10 px stroke width.

### Task 5: Add avatar selection UI and connect the settings card

**Files:**
- Modify: `entry/src/main/ets/pages/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`

- [ ] **Step 1: Add a visible avatar preview and picker state to `ProfilePage`.**

Add `@State showAvatarPicker: boolean = false`, import `AVATAR_OPTIONS` and `avatarGlyph`, and insert a profile card above the nickname field. The card opens the picker; the picker uses `Flex({ wrap: FlexWrap.Wrap })` with six built-in options and writes only `this.profile!.avatarId` until the existing Save action runs.

- [ ] **Step 2: Preserve modal dismissal and save semantics.**

Render the picker as the top layer of the page `Stack`: a dimmed full-height background closes it, and the bottom panel has a title, avatar grid, and cancel action. Selecting an avatar closes the panel. The existing `save()` remains the only persistence call and continues to emit `refreshSignal` before `router.back()`.

- [ ] **Step 3: Render the persisted avatar in `SettingsPage`.**

Add `@State avatarId: string = DEFAULT_AVATAR_ID`, load `profile.avatarId` in `loadSettings`, and replace the hard-coded emoji with `avatarGlyph(this.avatarId)`. Keep the profile card click routing to `ProfilePage`.

- [ ] **Step 4: Run the compile task and verify profile UI fields.**

Run the available Hvigor compile/build command. Expected result: profile and settings pages compile with the avatar catalog and no changes to goal calculation behavior.

### Task 6: Full verification and device behavior check

**Files:**
- Read: all files listed above
- Modify: only files needed to fix verified failures

- [ ] **Step 1: Run the complete unit test task.**

Run `hvigorw test`. Expected result: all existing and new Hypium assertions pass with zero failures.

- [ ] **Step 2: Build an installable HAP.**

Run `hvigorw assembleHap` or the installed Hvigor equivalent confirmed by the project. Expected result: exit code 0 and a generated HAP under the normal build output directory.

- [ ] **Step 3: Verify the navigation and avatar flows on the available device/emulator.**

Open the main page, drag horizontally across the content area, and verify the selected bottom tab does not change. Tap each bottom item and verify the corresponding page appears. Open Settings, open the profile card, select a different built-in avatar, save, and verify the settings card still shows it after leaving and re-entering the page.

- [ ] **Step 4: Verify reminder persistence and mode differences.**

Set a short interval and narrow time range, save with 温柔, verify the saved config after reopening, and observe a notification without an app-provided ring/snooze action. Repeat with 积极 and verify the alarm request has the short ring, close action, and one snooze action. Turn reminders off and verify the old reminders are cancelled. Record any system notification permission limitation separately from app scheduling failures.

- [ ] **Step 5: Verify the progress-ring overlap state.**

Use a completed goal state matching the supplied screenshot and verify the black Gauge pointer is absent while the water drop and ring remain. Use a non-complete state such as 86% and verify the pointer remains visible.

- [ ] **Step 6: Inspect the final diff and report the exact verification evidence.**

Run `git status --short` and `git diff --check`; if Git remains unavailable, report that limitation and use file listings plus build/test output instead. Do not claim completion without the fresh test and build outputs.
