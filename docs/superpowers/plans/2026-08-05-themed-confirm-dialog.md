# Themed Confirm Dialog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every confirmation and informational dialog follow the app's light and dark theme.

**Architecture:** Add one `@CustomDialog` component that receives semantic colors and callbacks. Replace all four `promptAction.showDialog` calls with page or component-owned `CustomDialogController` instances, recreating each controller immediately before opening it so the current theme and record data are used.

**Tech Stack:** ArkTS, ArkUI `@CustomDialog`, HarmonyOS Hypium, HDC emulator.

---

### Task 1: Prevent Native Dialog Regression

**Files:**
- Test: `entry/src/main/ets/**/*.ets`

- [ ] **Step 1: Write the failing regression check**

Run:

```powershell
$matches = rg -n 'promptAction\.showDialog' entry/src/main/ets
if ($LASTEXITCODE -eq 0) { $matches; exit 1 }
if ($LASTEXITCODE -eq 1) { exit 0 }
exit $LASTEXITCODE
```

Expected: failure listing the four native dialog call sites.

### Task 2: Add Themed Dialog Component

**Files:**
- Create: `entry/src/main/ets/components/ThemedConfirmDialog.ets`

- [ ] **Step 1: Implement the reusable dialog**

Use `@CustomDialog` and accept `title`, `message`, `confirmText`, `showCancel`, semantic colors, `controller`, and `onConfirm`. The card uses `cardColor`, the body and heading use `textColor`, cancel uses `surfaceColor`, and confirmation uses `confirmColor`.

### Task 3: Replace Native Dialog Callers

**Files:**
- Modify: `entry/src/main/ets/components/DrinkRecordItem.ets`
- Modify: `entry/src/main/ets/pages/RecordDetailPage.ets`
- Modify: `entry/src/main/ets/pages/DataManagePage.ets`
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`

- [ ] **Step 1: Replace each `promptAction.showDialog` call**

Create and open a `CustomDialogController` with `ThemedConfirmDialog`. Keep existing confirm callbacks unchanged: record removal invokes `onRecordDelete`, detail removal invokes `deleteAndBack`, reset invokes `doReset`, and About only closes.

### Task 4: Verify

**Files:**
- Test: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: Run the native-dialog regression check**

Run the Task 1 command. Expected: exit code 0.

- [ ] **Step 2: Build and run tests**

Run `hvigorw.bat assembleHap --mode module -p module=entry -p product=default`, install the output HAP files with HDC, then execute `aa test -b com.aquaflow.waterreminder -m entry_test -s unittest OpenHarmonyTestRunner -s timeout 60000 -w 90000`. Expected: successful build and 38 passing tests.

- [ ] **Step 3: Validate visual behavior**

Open a record deletion dialog in dark mode. Expected: dark card and readable text, while confirming deletion immediately refreshes statistics.
