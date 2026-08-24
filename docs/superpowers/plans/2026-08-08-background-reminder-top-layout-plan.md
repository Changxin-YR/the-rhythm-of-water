# Background Reminder and Top-Aligned Short Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove system-owned cross-application reminder delivery and prevent short data-management content from vertically centering.

**Architecture:** Keep Reminder Agent as the single scheduler and verify it on the connected device. Fix short-content layout at the Scroll child boundary by giving the child the viewport as its minimum height and explicitly using start alignment.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, Reminder Agent, Hypium, Hvigor, HDC UI inspection.

---

## File Map

- Create `tools/verify_data_manage_top_layout.ps1`: rendered-layout regression guard for the top-coordinate contract.
- Modify `entry/src/main/ets/pages/DataManagePage.ets`: top-anchor the page and short scroll content.
- Read `entry/src/main/ets/services/ReminderService.ets`: verify the system scheduling path without replacing it.
- Read `entry/src/main/module.json5`: verify the reminder and vibration permissions.
- Create device evidence under `device-evidence/`: final hierarchy, screenshot, and reminder observation logs.

### Task 1: Add the failing rendered-layout contract

- [ ] Create `tools/verify_data_manage_top_layout.ps1` so it reads a captured UI hierarchy, locates a Scroll with a direct Column child, and exits nonzero when their top coordinates differ by more than one layout pixel.
- [ ] Run `powershell -ExecutionPolicy Bypass -File tools/verify_data_manage_top_layout.ps1 -LayoutPath device-evidence/waterreminder-final-data-header-api22.json` and confirm it fails with Scroll top `318` and content top `660`.

### Task 2: Top-align short content

- [ ] Change the outer `Stack` to `Alignment.TopStart`.
- [ ] Apply `.constraintSize({ minHeight: '100%' })`, `.justifyContent(FlexAlign.Start)`, and `.width('100%')` to the Scroll child `Column`.
- [ ] Capture a fresh hierarchy and re-run `powershell -ExecutionPolicy Bypass -File tools/verify_data_manage_top_layout.ps1 -LayoutPath <fresh-layout.json>`; confirm both top coordinates match and it exits zero.

### Task 3: Build and rendered-layout verification

- [ ] Run the available Hvigor test task and the debug HAP build; require zero test failures and exit code 0.
- [ ] Install the HAP on `127.0.0.1:5555`, open Data Management, capture the screenshot and layout hierarchy.
- [ ] Compare the Scroll bounds with its direct child Column bounds. Their top coordinates must match within layout rounding, while the child may extend beyond the viewport on smaller screens.

### Task 4: Cross-application reminder verification

- [ ] Back up the device's `reminder_config` preference file.
- [ ] Configure and publish one near-future active reminder through the application, confirm Reminder Agent reports a successful publication, and place WaterReminder in the background.
- [ ] Keep another app in the foreground until the due time; capture the visible system reminder and relevant system/application logs.
- [ ] Restore the original `reminder_config`, relaunch WaterReminder, and republish the original schedule so verification does not leave altered user settings.

### Task 5: Final checks

- [ ] Re-run the layout contract, complete Hypium suite, and debug build from a clean invocation.
- [ ] Confirm the final evidence proves both requirements: a background reminder and a top-anchored Data Management Scroll child.
- [ ] Report any platform policy limitation separately from application correctness. This workspace is not a Git repository, so no commit step is available.
