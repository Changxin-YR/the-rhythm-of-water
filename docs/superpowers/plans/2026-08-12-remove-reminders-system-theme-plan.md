# Remove Reminders and Follow System Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all in-app water reminder functionality and make the app's light/dark appearance always follow HarmonyOS.

**Architecture:** Delete the reminder page, service, configuration persistence, backup field, routes, and every caller rather than leaving an inactive feature behind. Retain the existing `colorMode` AppStorage value populated by `EntryAbility`; remove the user-selectable theme mode and derive each page's palette directly from that value, refreshing page state when it changes.

**Tech Stack:** ArkTS, ArkUI, HarmonyOS `ConfigurationConstant.ColorMode`, existing Hypium tests, Hvigor.

---

### Task 1: Remove reminder behavior end to end

**Files:**
- Delete: `entry/src/main/ets/pages/ReminderSettingsPage.ets`
- Delete: `entry/src/main/ets/services/ReminderService.ets`
- Delete: `entry/src/main/ets/models/ReminderConfig.ets`
- Modify: `entry/src/main/ets/pages/HomePage.ets`
- Modify: `entry/src/main/ets/pages/OnboardingPage.ets`
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`
- Modify: `entry/src/main/ets/services/PreferencesService.ets`
- Modify: `entry/src/main/ets/services/BackupService.ets`
- Modify: `entry/src/main/ets/common/BackupRules.ets`
- Modify: `entry/src/main/ets/common/Constants.ets`
- Modify: `entry/src/main/ets/common/Routes.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: `entry/src/main/module.json5`
- Test: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] Remove reminder imports, controls, persistence, backup data, route declarations, permissions, model/service/page files, and reminder-only tests.
- [ ] Build the app and test HAP; the compiler must find no import or route to removed reminder code.

### Task 2: Make appearance system-controlled

**Files:**
- Modify: `entry/src/main/ets/common/Theme.ets`
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`
- Modify: every `entry/src/main/ets/**/*.ets` page that reads `colorMode` or `themeMode`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] Replace theme-mode-specific palette selection with a helper that maps `colorMode` directly to dark/light.
- [ ] Remove the theme-mode control from settings and normalize legacy settings to `system` on read.
- [ ] Add a `colorMode` watch to `MainPage`; its refreshed shared palette is passed to every tab page, and `EntryAbility.onConfigurationUpdate` updates AppStorage.
- [ ] Add a pure test that proves light and dark system modes choose opposite palettes, run it red, then make it pass.

### Task 3: Verify the reduced app

**Files:**
- Test: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] Run the full Hypium suite on-device if the connected emulator is available.
- [ ] Run `hvigorw.bat assembleHap --mode module -p module=entry -p product=default --no-daemon` and require exit code 0.
- [ ] Run a source audit for removed reminder symbols and ensure only historical documentation/artifacts retain them.
