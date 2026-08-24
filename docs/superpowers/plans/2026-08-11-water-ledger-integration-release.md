# Water and Ledger Integration Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship one HarmonyOS app that combines WaterReminder with an empty local ledger and resolves the navigation, contrast, and reminder-review findings.

**Architecture:** Keep WaterReminder as the Stage entry and add the ledger under `ets/ledger/`, so its RDB tables, services and pages remain isolated from hydration data. `MainPage` owns the only persistent bottom navigation; the imported ledger changes its former lower tab bar into a top tab switcher. System-bar state is centralised in `SystemBarService` and consumed by both modules.

**Tech Stack:** ArkTS, ArkUI, HarmonyOS API 22, Preferences, RDB, BackgroundTasksKit, Hypium.

This source folder has no `.git` directory, so commit steps are intentionally omitted.

---

## File Structure

- Modify `entry/src/main/ets/common/SafeAreaRules.ets`: expose the 28vp bottom-control clearance rule.
- Create `entry/src/main/ets/common/ColorContrast.ets`: pure sRGB contrast helpers for release checks.
- Modify `entry/src/main/ets/services/SystemBarService.ets` and `entry/src/main/ets/entryability/EntryAbility.ets`: publish top and bottom safe-area values.
- Modify `entry/src/main/ets/common/Theme.ets`: use contrast-safe WaterReminder semantic colors.
- Modify `entry/src/main/ets/pages/MainPage.ets` and `entry/src/main/ets/common/DataRefresh.ets`: add the ledger main tab and keep achievement refresh selection correct.
- Create `entry/src/main/ets/ledger/{common,components,models,pages,services}/...`: port random-ledger implementation with a separate database and route namespace.
- Modify `entry/src/main/resources/base/{element,color.json,element,string.json,profile/main_pages.json}` and add `resources/base/media/ledger_*`: import ledger resources and routes.
- Modify `entry/src/main/ets/services/ReminderService.ets`: make missing-agent-capability feedback explicitly non-successful.
- Modify `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets` and create `entry/src/ohosTest/ets/test/LedgerRules.test.ets`: verify safe-area, contrast, reminder, and ledger pure rules.

### Task 1: Add Release-Check Rules

**Files:**
- Modify: `entry/src/main/ets/common/SafeAreaRules.ets`
- Create: `entry/src/main/ets/common/ColorContrast.ets`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: Write failing safe-area and contrast tests**

```ts
import { minimumBottomControlInsetVp } from '../../../main/ets/common/SafeAreaRules'
import { hasMinimumTextContrast } from '../../../main/ets/common/ColorContrast'

expect(minimumBottomControlInsetVp(0)).assertEqual(28)
expect(minimumBottomControlInsetVp(36)).assertEqual(36)
expect(hasMinimumTextContrast('#52677C', '#F4FAFF')).assertTrue()
expect(hasMinimumTextContrast('#718398', '#F4FAFF')).assertFalse()
```

- [ ] **Step 2: Run the rule test and confirm the new imports fail**

Run: `hvigorw assembleHap --no-daemon --mode module -p product=default -p buildMode=debug`

Expected: compilation fails because `minimumBottomControlInsetVp` and `ColorContrast` do not yet exist.

- [ ] **Step 3: Add the two pure helpers**

```ts
export const MIN_BOTTOM_CONTROL_CLEARANCE_VP: number = 28

export function minimumBottomControlInsetVp(safeAreaBottomVp: number): number {
  return Math.max(MIN_BOTTOM_CONTROL_CLEARANCE_VP, normalizeSafeAreaHeightPx(safeAreaBottomVp))
}
```

```ts
export function hasMinimumTextContrast(foreground: string, background: string): boolean {
  return contrastRatio(foreground, background) >= 4.5
}
```

`contrastRatio` must parse six-digit hex colors, convert sRGB channels to relative luminance, and return `(lighter + 0.05) / (darker + 0.05)`. Invalid colors return `0` rather than passing a check.

- [ ] **Step 4: Run the rule test and confirm it passes**

Run: `hvigorw assembleHap --no-daemon --mode module -p product=default -p buildMode=debug`

Expected: exit code `0`.

### Task 2: Correct Safe-Area Publication and Main Navigation

**Files:**
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`
- Modify: `entry/src/main/ets/services/SystemBarService.ets`
- Modify: `entry/src/main/ets/pages/MainPage.ets`
- Modify: `entry/src/main/ets/common/DataRefresh.ets`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: Add a failing tab-selection regression test**

```ts
expect(shouldRefreshAchievementOnTabSelection(0, 3)).assertTrue()
expect(shouldRefreshAchievementOnTabSelection(3, 2)).assertFalse()
```

- [ ] **Step 2: Publish the bottom system inset from the shared service**

```ts
const avoidArea = activeWindow.getWindowAvoidAreaIgnoringVisibility(window.AvoidAreaType.TYPE_SYSTEM)
const safeAreaTop = activeWindow.getUIContext().px2vp(normalizeSafeAreaHeightPx(avoidArea.topRect.height))
const safeAreaBottom = activeWindow.getUIContext().px2vp(normalizeSafeAreaHeightPx(avoidArea.bottomRect.height))
AppStorage.setOrCreate<number>('safeAreaTop', safeAreaTop)
AppStorage.setOrCreate<number>('safeAreaBottom', safeAreaBottom)
```

Set `safeAreaBottom` to `0` in `EntryAbility.onCreate` so every page has a defined value before the first window read.

- [ ] **Step 3: Make the main bottom bar obey the shared clearance**

```ts
@StorageProp('safeAreaBottom') safeAreaBottom: number = 0

private bottomControlInset(): number {
  return minimumBottomControlInsetVp(this.safeAreaBottom)
}
```

Wrap the existing main-tab `Row` in a `Column` with a fixed 80vp tab row and bottom padding equal to `bottomControlInset()`. The wrapper height is `UiTokens.bottomBarHeight + bottomControlInset()` so labels and hit targets are lifted rather than compressed.

- [ ] **Step 4: Add the fifth primary tab without duplicating the bottom bar**

Use the order `HomePage`, `StatsPage`, `LedgerHomePage`, `AchievementPage`, `SettingsPage`. Change the achievement index in `DataRefresh` from `2` to `3`; update the `TabBuilder` icon branch and rendered page visibility to use the same indices.

- [ ] **Step 5: Run the focused build check**

Run: `hvigorw assembleHap --no-daemon --mode module -p product=default -p buildMode=debug`

Expected: exit code `0`; the prior refresh test passes with index `3`.

### Task 3: Enforce Contrast-Safe Theme Tokens

**Files:**
- Modify: `entry/src/main/ets/common/Theme.ets`
- Modify: `entry/src/main/resources/base/element/color.json`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: Add failing checks for the rendered text/token pairs**

```ts
expect(hasMinimumTextContrast(light.textPrimary, light.background)).assertTrue()
expect(hasMinimumTextContrast(light.textSecondary, light.background)).assertTrue()
expect(hasMinimumTextContrast('#FFFFFF', light.primary)).assertTrue()
expect(hasMinimumTextContrast('#FFFFFF', light.success)).assertTrue()
expect(hasMinimumTextContrast(dark.textPrimary, dark.background)).assertTrue()
expect(hasMinimumTextContrast(dark.textSecondary, dark.background)).assertTrue()
```

- [ ] **Step 2: Replace unsafe semantic colors, not individual text instances**

Set the light secondary text to `#52677C`, use `#0077B6` for the default blue action color, `#2E7D32` for success, `#9A4C00` for warning, and `#C62828` for danger. Apply equally dark enough theme-color overrides where white text is shown on a selected button. Keep light and dark surface colors unchanged unless a token needs a contrasting companion.

- [ ] **Step 3: Keep static resource colors consistent with the Theme tokens**

Update the WaterReminder resource aliases used before settings load so `text_secondary`, `success`, `warning`, and `primary` do not introduce a lower-contrast first frame.

- [ ] **Step 4: Run contrast and build verification**

Run: `hvigorw assembleHap --no-daemon --mode module -p product=default -p buildMode=debug`

Expected: exit code `0` and all new contrast assertions pass.

### Task 4: Port the Empty Ledger Data Layer

**Files:**
- Create: `entry/src/main/ets/ledger/common/{Constants,DataChangeNotifier,DateUtils,NumberUtils,ResponsiveUtils}.ets`
- Create: `entry/src/main/ets/ledger/models/{BillRecord,Category,Statistics}.ets`
- Create: `entry/src/main/ets/ledger/services/{DatabaseHelper,BillService,BudgetService,CategoryService,StatisticsService,StreakService}.ets`
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`
- Create: `entry/src/ohosTest/ets/test/LedgerRules.test.ets`
- Modify: `entry/src/test/List.test.ets`

- [ ] **Step 1: Copy pure ledger utility and model sources under the `ledger` boundary**

Copy the five `common` and three `models` files from `C:\Users\27363\Desktop\APP\JiZhangBen\entry\src\main\ets` into their matching `ledger/` directories. Retain relative imports inside that boundary; do not merge ledger `Constants` or `DateUtils` with WaterReminder equivalents.

- [ ] **Step 2: Add failing tests for the copied pure rules**

```ts
import { DateUtils } from '../../../main/ets/ledger/common/DateUtils'
import { NumberUtils } from '../../../main/ets/ledger/common/NumberUtils'

expect(DateUtils.getMonthRange(2026, 2).end).assertEqual('2026-02-28')
expect(NumberUtils.formatAmount(1234.5)).assertEqual('1,234.50')
```

Register the new test function from `entry/src/test/List.test.ets`.

- [ ] **Step 3: Copy the six RDB service files with an empty-only database initializer**

Set the database name to `waterreminder_ledger.db`. Delete the `@ohos.data.preferences` import, `MIGRATION_KEY`, and `migrateLegacyPreferences` method from `ledger/services/DatabaseHelper.ets`; keep table creation, the empty streak row, and default category insertion.

- [ ] **Step 4: Initialize the ledger database before the app loads content**

```ts
async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
  try {
    await LedgerDatabaseHelper.getInstance().initDatabase(this.context)
  } catch (error) {
    hilog.error(0x0000, 'AquaFlow', 'Ledger database initialization failed: %{public}s', JSON.stringify(error))
    return
  }
  windowStage.loadContent('pages/MainPage', (err) => {
    if (err.code) {
      hilog.error(0x0000, 'AquaFlow', 'Failed to load content: %{public}s', JSON.stringify(err))
    }
  })
}
```

Rename the imported helper to `LedgerDatabaseHelper` at import use-site only; its implementation stays within the ledger directory.

- [ ] **Step 5: Build the new module boundary**

Run: `hvigorw assembleHap --no-daemon --mode module -p product=default -p buildMode=debug`

Expected: exit code `0`; a clean install creates an empty `waterreminder_ledger.db` and its default categories.

### Task 5: Port Ledger Components, Resources, and Routes

**Files:**
- Create: `entry/src/main/ets/ledger/components/{BillCard,CategoryGrid,LedgerIcon,LineChart,NumberKeyboard,PieChart,SummaryCard}.ets`
- Create: `entry/src/main/ets/ledger/pages/{LedgerHomePage,LedgerAddBillPage,LedgerEditBillPage,LedgerStatisticsPage,LedgerCategoryManagePage,LedgerBudgetPage}.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: `entry/src/main/resources/base/element/{color,string,float}.json`
- Create: `entry/src/main/resources/base/media/ledger_*.svg`

- [ ] **Step 1: Copy the seven ledger components and the fourteen `ledger_*.svg` assets**

Update `BillCard` navigation to `pages/ledger/LedgerEditBillPage`. Do not copy the random-ledger app icons because the integrated application keeps the WaterReminder icon.

- [ ] **Step 2: Add all ledger-only resources under unique names**

Merge the random-ledger strings, floats and colors into the current resource files. Rename generic resource identifiers (`tab_home`, `tab_bills`, `tab_statistics`, `tab_settings`, `income`, `expense`, `save`, `cancel`, `delete`, `confirm`, `text_primary`, `text_secondary`, and `start_window_background`) with the `ledger_` prefix, then update ledger `$r()` calls to use those names.

Use contrast-safe ledger text values: `ledger_ink #18233D`, `ledger_muted #52627C`, `ledger_category_fallback #667085`, and `ledger_tab_inactive #667085`. Retain `ledger_accent #5B5CE2`; replace any semi-transparent white ledger caption used on that accent with an opacity that still passes 4.5:1.

- [ ] **Step 3: Create the ledger route pages from their random-ledger counterparts**

Use these routes exactly:

```json
[
  "pages/ledger/LedgerAddBillPage",
  "pages/ledger/LedgerEditBillPage",
  "pages/ledger/LedgerStatisticsPage",
  "pages/ledger/LedgerCategoryManagePage",
  "pages/ledger/LedgerBudgetPage"
]
```

Every copied route page retains `@Entry`, changes imports to the local `ledger` boundary, and replaces `ledgerSystemBarTopInset`/`ledgerSystemBarBottomInset` with the shared numeric `safeAreaTop`/`safeAreaBottom`. Header padding uses `safeAreaTop`; a fixed bottom keyboard or action area uses `minimumBottomControlInsetVp(safeAreaBottom)`.

- [ ] **Step 4: Create the embedded ledger root**

Copy `Index.ets` to `LedgerHomePage.ets`, remove `@Entry`, rename its struct `LedgerHomePage`, and change all routes to the five names above. Keep its four content areas but change `Tabs({ barPosition: BarPosition.End })` to `BarPosition.Start`, remove the previous bottom inset bar-height calculation, and give the top tab strip a fixed 48vp height.

- [ ] **Step 5: Register and compile all ledger routes**

Run: `hvigorw assembleHap --no-daemon --mode module -p product=default -p buildMode=debug`

Expected: exit code `0`; no duplicated resource identifier or `@Entry` error is reported.

### Task 6: Attach the Ledger to the Unified App Shell

**Files:**
- Modify: `entry/src/main/ets/pages/MainPage.ets`
- Modify: `entry/src/main/ets/common/DataRefresh.ets`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: Import and render the ledger root in the third main-tab slot**

```ts
import { LedgerHomePage } from '../ledger/pages/LedgerHomePage'

Column() { LedgerHomePage() }
  .width('100%')
  .height('100%')
  .visibility(this.currentIndex === 2 ? Visibility.Visible : Visibility.None)
```

- [ ] **Step 2: Shift achievement and settings to indices three and four**

Use a fifth tab item `{ label: '账本' }`, a `SymbolGlyph` for the ledger tab, and the same `TabBuilder` dimensions used by the other four tabs. `AchievementPage` uses index `3`; `SettingsPage` uses index `4`; refresh logic uses the named achievement index from `DataRefresh`.

- [ ] **Step 3: Build and inspect route reachability**

Run: `hvigorw assembleHap --no-daemon --mode module -p product=default -p buildMode=debug`

Expected: exit code `0`; `rg -n "pages/ledger/" entry/src/main/resources/base/profile/main_pages.json entry/src/main/ets/ledger` prints all five route names.

### Task 7: Make Reminder Results Explicitly Non-Successful When Capability Is Missing

**Files:**
- Modify: `entry/src/main/ets/services/ReminderService.ets`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: Preserve the existing failure classification regression check**

```ts
expect(classifyReminderPublishFailure(1700002, 0, 0)).assertEqual('capability')
expect(classifyReminderSchedule(true, 3, 0, 'capability')).assertEqual('capability_required')
```

- [ ] **Step 2: Change only the capability feedback copy**

For `capability_required`, return a message that starts with `提醒未生效` and instructs the user to open the capability in AppGallery Connect, download a new signed Profile, rebuild, and retry. Do not describe this state as a successful save or a created reminder.

- [ ] **Step 3: Confirm no false success path remains**

Run: `hvigorw assembleHap --no-daemon --mode module -p product=default -p buildMode=debug`

Expected: exit code `0`; `ReminderSettingsPage` only returns when `status` is `published` or `disabled`.

### Task 8: Release Verification

**Files:**
- Modify: `docs/superpowers/specs/2026-08-11-water-ledger-integration-release-design.md` only if the shipped behavior differs from the approved design.

- [ ] **Step 1: Run the full test and release build**

Run: `hvigorw assembleHap --no-daemon --mode module -p product=default -p buildMode=release`

Expected: exit code `0` and a non-empty HAP under `entry/build/default/outputs/default`.

- [ ] **Step 2: Verify static release conditions**

Run:

```powershell
rg -n "safeAreaBottom|minimumBottomControlInsetVp|LedgerHomePage|pages/ledger" entry/src/main
rg -n "提醒未生效|capability_required" entry/src/main/ets/services/ReminderService.ets
```

Expected: the shared bottom inset reaches the app shell and ledger pages; all ledger routes are declared; capability feedback is non-successful.

- [ ] **Step 3: Verify on API 22 hardware after the user enables the AGC capability**

Install the release HAP, capture the main five-tab screen and each ledger subpage, and inspect that every bottom control is at least 28vp above the system navigation indicator. Save an enabled reminder before and after applying the new AGC Profile: before it, the screen must say `提醒未生效`; after it, a near-future reminder must appear while the app is backgrounded.

## Plan Self-Review

- Spec coverage: Tasks 1-3 cover bottom avoidance and color contrast; Tasks 4-6 cover every random-ledger data, UI, resource and routing requirement; Task 7 covers honest reminder feedback; Task 8 covers release and device acceptance.
- Placeholder scan: no deferred implementation steps or unspecified files remain.
- Type consistency: both modules use their own `Constants`/`DateUtils` paths, while `safeAreaTop`, `safeAreaBottom`, `minimumBottomControlInsetVp`, and the `pages/ledger/...` routes are named consistently throughout.
