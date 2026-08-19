# WaterReminder Release Compliance Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a compliant faithful layered icon, enable immersive layout, export backups through the system save picker, and verify API 22 / HarmonyOS 6.0.2 compatibility.

**Architecture:** Keep the existing service/page boundaries. Pure filename and system-bar decisions remain in testable common helpers; file picker UI stays in `DataManagePage`, and byte writing stays in `BackupService`. AppScope and entry receive identical layered icon resources so resource merge behavior remains deterministic.

**Tech Stack:** ArkTS, ArkUI, Core File Kit, HarmonyOS layered-image resources, Hypium, Hvigor, HDC, ImageGen.

**Repository note:** This directory is not a Git repository, so commit steps are replaced by explicit verification checkpoints.

---

### Task 1: Enable Immersive Layout With TDD

**Files:**
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets:25`
- Modify: `entry/src/main/ets/common/SystemBarAppearance.ets:16`

- [ ] **Step 1: Change the existing test to require immersive layout**

Replace both assertions with:

```ts
expect(dark.useImmersiveLayout).assertTrue()
expect(light.useImmersiveLayout).assertTrue()
```

- [ ] **Step 2: Build, install, and run the test bundle to verify RED**

Run:

```powershell
hvigorw.bat assembleHap --mode module -p module=entry@ohosTest -p product=default --no-daemon
hdc -t 127.0.0.1:5555 install -r entry\build\default\outputs\ohosTest\entry-ohosTest-signed.hap
hdc -t 127.0.0.1:5555 shell aa test -b com.aquaflow.waterreminder -m entry_test -s unittest OpenHarmonyTestRunner -s timeout 60000 -w 90000
```

Expected: the light and dark immersive assertions fail because production still returns `false`.

- [ ] **Step 3: Implement the minimal production change**

Change the return value in `resolveSystemBarAppearance()`:

```ts
useImmersiveLayout: true,
```

- [ ] **Step 4: Rebuild, reinstall, and rerun all Hypium tests**

Expected: all tests pass, including both immersive assertions.

### Task 2: Add Testable Backup Filename Behavior

**Files:**
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`
- Modify: `entry/src/main/ets/common/BackupRules.ets`

- [ ] **Step 1: Add a failing filename test**

Import `buildBackupFileName` from `BackupRules` and add:

```ts
it('buildsStableTimestampedBackupFileNames', 0, (): void => {
  expect(buildBackupFileName(1786090000123)).assertEqual('aquaflow_backup_1786090000123.json')
  expect(buildBackupFileName(Number.NaN)).assertEqual('aquaflow_backup.json')
})
```

- [ ] **Step 2: Build the ohosTest HAP to verify RED**

Expected: ArkTS compilation fails because `buildBackupFileName` is not exported.

- [ ] **Step 3: Add the minimal helper**

Add to `BackupRules.ets`:

```ts
export function buildBackupFileName(timestamp: number): string {
  if (!Number.isFinite(timestamp) || timestamp < 0) return 'aquaflow_backup.json'
  return `aquaflow_backup_${Math.floor(timestamp)}.json`
}
```

- [ ] **Step 4: Rebuild, reinstall, and rerun all tests**

Expected: the new filename test and all existing tests pass.

### Task 3: Export Backups to a User-Selected URI

**Files:**
- Modify: `entry/src/main/ets/services/BackupService.ets:81`
- Modify: `entry/src/main/ets/pages/DataManagePage.ets:16`

- [ ] **Step 1: Replace private-directory writing with target-URI writing**

Replace `saveToFile(content)` with:

```ts
async writeToFile(fileUri: string, content: string): Promise<void> {
  let fd = -1
  try {
    const file = fileIo.openSync(
      fileUri,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC
    )
    fd = file.fd
    fileIo.writeSync(fd, content)
  } finally {
    if (fd >= 0) fileIo.closeSync(fd)
  }
}
```

- [ ] **Step 2: Open the save picker before writing**

Update `DataManagePage.doBackup()`:

```ts
private async doBackup(): Promise<void> {
  try {
    const options = new picker.DocumentSaveOptions()
    options.newFileNames = [buildBackupFileName(Date.now())]
    const targetUris = await new picker.DocumentViewPicker(getContext(this)).save(options)
    if (!targetUris || targetUris.length === 0) return

    const content = await this.backupService.exportData()
    await this.backupService.writeToFile(targetUris[0], content)
    this.lastBackupPath = targetUris[0]
    this.message = '备份成功，文件已保存'
  } catch (e) {
    this.message = '备份失败，请稍后重试'
  }
}
```

Add the import:

```ts
import { buildBackupFileName } from '../common/BackupRules'
```

- [ ] **Step 3: Update the success label**

Replace `已保存到应用目录` with `备份文件已保存` and keep it conditional on `lastBackupPath`.

- [ ] **Step 4: Run type checking and the complete test suite**

Expected: ArkTS compiles with `DocumentViewPicker(context)`, `DocumentSaveOptions`, and `OpenMode.TRUNC`; all tests pass.

### Task 4: Generate and Wire the Faithful Layered Icon

**Files:**
- Create: `AppScope/resources/base/media/app_icon_foreground.png`
- Create: `AppScope/resources/base/media/app_icon_background.png`
- Create: `AppScope/resources/base/media/app_icon_layered.json`
- Create: `entry/src/main/resources/base/media/app_icon_foreground.png`
- Create: `entry/src/main/resources/base/media/app_icon_background.png`
- Create: `entry/src/main/resources/base/media/app_icon_layered.json`
- Modify: `AppScope/app.json5:7`
- Modify: `entry/src/main/module.json5:16`
- Modify: `entry/src/main/module.json5:18`
- Modify: `release-assets/WaterReminder-AppGallery-icon-1024x1024.png`

- [ ] **Step 1: Use ImageGen to create the two layers from the approved reference**

Use `release-assets/WaterReminder-app-icon-1024x1024.png` as the visual reference. Generate:

- A transparent `1024 x 1024` foreground containing the same water drop, glass, splashes, leaf, and necessary local shadow; no background, border, rounded mask, or external margin.
- An opaque `1024 x 1024` square light-blue background that matches the original palette; no rounded mask, border, text, or logo subject.

- [ ] **Step 2: Copy identical layer files into AppScope and entry**

Verify AppScope and entry foreground hashes match, and background hashes match.

- [ ] **Step 3: Add the layered-image descriptor in both resource scopes**

```json
{
  "layered-image": {
    "background": "$media:app_icon_background",
    "foreground": "$media:app_icon_foreground"
  }
}
```

- [ ] **Step 4: Point application and ability icons at the layered resource**

Use:

```json5
"icon": "$media:app_icon_layered"
```

For the UIAbility startup window, use:

```json5
"startWindowIcon": "$media:app_icon_foreground"
```

- [ ] **Step 5: Produce the AppGallery composite**

Alpha-compose the foreground over the background at `1024 x 1024` without adding a rounded mask, border, or inner padding, and replace `release-assets/WaterReminder-AppGallery-icon-1024x1024.png`.

- [ ] **Step 6: Validate icon metadata and pixels**

Expected:

- All layer and listing assets are `1024 x 1024` PNG.
- Foreground is RGBA and has transparent corner pixels.
- Background and listing composite are fully opaque.
- No dark top line or baked white rounded border is visible.
- Resource descriptors parse and reference existing files.

### Task 5: Build and Verify API 22 Release Artifacts

**Files:**
- Verify: `build-profile.json5:22`
- Verify: `entry/build/default/outputs/default/entry-default-signed.hap`

- [ ] **Step 1: Build release HAP**

```powershell
hvigorw.bat assembleHap --mode module -p module=entry -p product=default -p buildMode=release --no-daemon
```

Expected: `BUILD SUCCESSFUL` and type checking successful.

- [ ] **Step 2: Inspect final HAP metadata**

Extract `module.json` and verify:

```text
targetAPIVersion = 60002022
minAPIVersion = 60002022
buildMode = release
```

- [ ] **Step 3: Install release HAP on the API 22 emulator**

```powershell
hdc -t 127.0.0.1:5555 install -r entry\build\default\outputs\default\entry-default-signed.hap
```

Expected: install succeeds on the device reporting API name `6.0.2` and API version `22`.

- [ ] **Step 4: Run complete tests again**

Expected: `Tests run: 41, Failure: 0, Error: 0, Pass: 41`.

- [ ] **Step 5: Perform device UI verification**

Check the desktop icon, cold start, light and dark system bars, data-management page, save picker, saved JSON file visibility, and restore selection. Capture screenshots under `device-evidence/` without changing unrelated application data.

- [ ] **Step 6: Recheck offline packaging**

Verify the packaged `module.json` has no `ohos.permission.INTERNET`, and source scanning still finds no NetworkKit, HTTP, fetch, axios, or WebSocket implementation.

