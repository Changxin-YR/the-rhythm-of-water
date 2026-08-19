# HarmonyOS Review Checklist Audit and Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recheck every item in `C:\Users\27363\Desktop\鸿蒙问题排查表.md`, fix every issue that still applies to WaterReminder, and record reproducible evidence for fixed and non-applicable findings.

**Architecture:** Keep UI behavior in the existing ArkUI pages and semantic theme tokens. Add a small release-audit PowerShell script for source/resource/package invariants, extend the existing Hypium rule suite for runtime color decisions, and use the connected API 22 emulator for final package and UI verification.

**Tech Stack:** ArkTS, ArkUI, HarmonyOS API 22, Hypium, Hvigor, HDC, PowerShell.

**Repository note:** This directory has no `.git` metadata, so commit steps are replaced by explicit verification checkpoints.

---

### Task 1: Add a Reproducible Release-Audit Gate

**Files:**
- Create: `tools/verify_harmony_review_checklist.ps1`
- Verify: `AppScope/app.json5`
- Verify: `entry/src/main/module.json5`
- Verify: `AppScope/resources/base/element/string.json`
- Verify: `entry/src/main/ets/**/*.ets`
- Verify: `entry/src/main/resources/{base,dark}/element/color.json`

- [x] **Step 1: Add checks for review invariants**

The script must fail when any production `fontSize()` literal is below `10fp`, the bottom-control clearance is below `28vp`, immersive layout is disabled, the app/ability icons do not use the same layered resource, duplicate icon layers differ, the app label is not `补水啦`, the reminder capability failure message falsely claims success, or the dark ledger palette lacks the semantic colors used by ledger pages.

- [x] **Step 2: Run the script and verify RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_harmony_review_checklist.ps1
```

Expected: FAIL because `PlantGardenPage.ets` contains `fontSize(9)` and the dark resource file does not yet define the ledger semantic palette.

### Task 2: Add Runtime Theme and Font Regression Tests

**Files:**
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`
- Modify: `entry/src/main/ets/common/Theme.ets`
- Create: `entry/src/main/ets/common/TypographyRules.ets`

- [x] **Step 1: Add failing theme tests**

Import `ThemeColor` and assert for all six theme choices that `colors.primaryText` has at least `4.5:1` contrast against both `colors.background` and `colors.card`, in light and dark mode.

- [x] **Step 2: Add a failing minimum-font test**

Import `MIN_READABLE_FONT_SIZE_FP` from the not-yet-created `TypographyRules` module and assert that it equals `10`.

- [x] **Step 3: Build the ohosTest HAP and verify RED**

Run:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@ohosTest -p product=default --no-daemon
```

Expected: ArkTS compilation fails because the new semantic token and typography rule are not implemented.

### Task 3: Fix Remaining Text-Size and Dark-Contrast Problems

**Files:**
- Create: `entry/src/main/ets/common/TypographyRules.ets`
- Modify: `entry/src/main/ets/common/Theme.ets`
- Modify: `entry/src/main/ets/pages/PlantGardenPage.ets`
- Modify: pages that render `themeColors.primary` as foreground text or glyph color

- [x] **Step 1: Add the minimum readable font token**

```ts
export const MIN_READABLE_FONT_SIZE_FP: number = 10
```

- [x] **Step 2: Use the token for the plant growth-stage labels**

Replace the `9fp` literal with `MIN_READABLE_FONT_SIZE_FP`.

- [x] **Step 3: Split brand fill from readable accent text**

Add `primaryText` to `ThemeColors`. In light mode it may match the dark brand fill; in dark mode it must use a lighter theme-specific accent. Use `primaryText` wherever primary is rendered as text or a glyph on a dark surface, while keeping `primary` for filled buttons whose text is white.

- [x] **Step 4: Run the Hypium build and static audit**

Expected: theme and typography tests compile; the static audit advances to the missing dark ledger resource failure only.

### Task 4: Add Dark Ledger Semantic Resources

**Files:**
- Modify: `entry/src/main/resources/dark/element/color.json`

- [x] **Step 1: Define dark overrides for every ledger semantic color used by UI pages**

Use dark canvas/card/surface backgrounds, readable primary/secondary/hint text, visible inactive tabs and dividers, and contrast-safe status/action colors. Preserve category palette colors unless they serve as readable text.

- [x] **Step 2: Run the static audit and verify GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_harmony_review_checklist.ps1
```

Expected: all source/resource review checks pass.

### Task 5: Build, Install, Test, and Record Every Checklist Result

**Files:**
- Modify: `C:\Users\27363\Desktop\鸿蒙问题排查表.md`
- Create: `device-evidence/waterreminder-review-final-*.png`

- [x] **Step 1: Run the complete Hypium suite**

Build and install the signed ohosTest HAP, then run `OpenHarmonyTestRunner`. Expected: zero failures and zero errors.

- [x] **Step 2: Build and install the release HAP**

Run the release Hvigor build, install `entry-default-signed.hap`, and verify package metadata reports target/min API 22, label `补水啦`, and `$media:app_icon_layered`.

- [x] **Step 3: Verify the original symptoms on the API 22 emulator**

Check status/navigation-bar clearance, five main pages without horizontal clipping, light/dark readability, and reminder failure feedback when agent capability is unavailable. Capture fresh screenshots and layout dumps.

- [x] **Step 4: Recheck icon assets and non-applicable features**

Confirm foreground/background copies are byte-identical and the AppGallery composite is `1024x1024`. Confirm event/default-view/focus/clock/white-noise features are absent from this WaterReminder bundle, so their foreign-app findings are marked non-applicable rather than implemented.

- [x] **Step 5: Append a result table to the supplied checklist**

For all 11 rows, record `已修复并验证`, `本轮修复并验证`, or `不适用于当前工程`, together with the concrete source/config/device evidence.
