# WaterReminder App Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the HarmonyOS application icon with the approved square-safe version of the supplied water-cup artwork.

**Architecture:** Keep the existing single-layer `$media:app_icon` references. Generate one cleaned `1024x1024` PNG, derive the `192x192` runtime PNG from it, and copy the same runtime resource into AppScope and entry so the existing resource merge remains deterministic.

**Tech Stack:** HarmonyOS Stage project, PNG assets, PowerShell `System.Drawing`, Hvigor release build.

---

### Task 1: Generate the cleaned icon assets

**Files:**
- Create: `docs/assets/water-reminder-app-icon.png`
- Modify: `AppScope/resources/base/media/app_icon.png`
- Modify: `entry/src/main/resources/base/media/app_icon.png`

- [x] **Step 1: Inspect the input image dimensions and color mode**

Run:

```powershell
Add-Type -AssemblyName System.Drawing
$source = [System.Drawing.Bitmap]::new('C:\Users\27363\AppData\Local\Temp\codex-clipboard-6461454c-f381-4cf0-b32e-c1a175092f09.png')
"$($source.Width)x$($source.Height) $($source.PixelFormat)"
$source.Dispose()
```

Expected: `1254x1254` and a non-alpha RGB pixel format.

- [x] **Step 2: Generate the cleaned high-resolution and runtime resources**

Create `docs/assets` and run a PowerShell image transform that fills the square with `#E9F7FF`, copies the supplied artwork into a centered square, and replaces only the corner-connected near-black background pixels before resizing the result to `192x192`:

```powershell
Add-Type -AssemblyName System.Drawing
$sourcePath = 'C:\Users\27363\AppData\Local\Temp\codex-clipboard-6461454c-f381-4cf0-b32e-c1a175092f09.png'
$highPath = 'C:\Users\27363\Desktop\APP\WaterReminder\docs\assets\water-reminder-app-icon.png'
$appPath = 'C:\Users\27363\Desktop\APP\WaterReminder\AppScope\resources\base\media\app_icon.png'
$entryPath = 'C:\Users\27363\Desktop\APP\WaterReminder\entry\src\main\resources\base\media\app_icon.png'
New-Item -ItemType Directory -Force -Path 'C:\Users\27363\Desktop\APP\WaterReminder\docs\assets' | Out-Null
$source = [System.Drawing.Bitmap]::new($sourcePath)
$clean = [System.Drawing.Bitmap]::new(1024, 1024, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$graphics = [System.Drawing.Graphics]::FromImage($clean)
$graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#E9F7FF'))
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, 1024, 1024))
$graphics.Dispose()
$pixels = $clean.LockBits([System.Drawing.Rectangle]::new(0, 0, 1024, 1024), [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$stride = $pixels.Stride
$bytes = New-Object byte[] ($stride * 1024)
[Runtime.InteropServices.Marshal]::Copy($pixels.Scan0, $bytes, 0, $bytes.Length)
$queue = [System.Collections.Generic.Queue[System.Drawing.Point]]::new()
$queue.Enqueue([System.Drawing.Point]::new(0, 0)); $queue.Enqueue([System.Drawing.Point]::new(1023, 0)); $queue.Enqueue([System.Drawing.Point]::new(0, 1023)); $queue.Enqueue([System.Drawing.Point]::new(1023, 1023))
$visited = New-Object bool[] (1024 * 1024)
while ($queue.Count -gt 0) {
  $point = $queue.Dequeue(); $index = $point.Y * 1024 + $point.X
  if ($visited[$index]) { continue }; $visited[$index] = $true
  $offset = $point.Y * $stride + $point.X * 3
  $blue = $bytes[$offset]; $green = $bytes[$offset + 1]; $red = $bytes[$offset + 2]
  if ($red -gt 28 -or $green -gt 28 -or $blue -gt 28) { continue }
  $bytes[$offset] = 255; $bytes[$offset + 1] = 247; $bytes[$offset + 2] = 233
  if ($point.X -gt 0) { $queue.Enqueue([System.Drawing.Point]::new($point.X - 1, $point.Y)) }
  if ($point.X -lt 1023) { $queue.Enqueue([System.Drawing.Point]::new($point.X + 1, $point.Y)) }
  if ($point.Y -gt 0) { $queue.Enqueue([System.Drawing.Point]::new($point.X, $point.Y - 1)) }
  if ($point.Y -lt 1023) { $queue.Enqueue([System.Drawing.Point]::new($point.X, $point.Y + 1)) }
}
[Runtime.InteropServices.Marshal]::Copy($bytes, 0, $pixels.Scan0, $bytes.Length)
$clean.UnlockBits($pixels)
$clean.Save($highPath, [System.Drawing.Imaging.ImageFormat]::Png)
$small = [System.Drawing.Bitmap]::new(192, 192, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$smallGraphics = [System.Drawing.Graphics]::FromImage($small)
$smallGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$smallGraphics.DrawImage($clean, [System.Drawing.Rectangle]::new(0, 0, 192, 192))
$smallGraphics.Dispose()
$small.Save($appPath, [System.Drawing.Imaging.ImageFormat]::Png)
$small.Save($entryPath, [System.Drawing.Imaging.ImageFormat]::Png)
$small.Dispose(); $clean.Dispose(); $source.Dispose()
```

Expected: all three PNG files exist and the two runtime files are byte-identical.

### Task 2: Validate resources and references

**Files:**
- Read: `AppScope/app.json5`
- Read: `entry/src/main/module.json5`
- Read: `docs/assets/water-reminder-app-icon.png`
- Read: `AppScope/resources/base/media/app_icon.png`
- Read: `entry/src/main/resources/base/media/app_icon.png`

- [x] **Step 1: Check dimensions, pixel format, corner colors, and equality**

Run a `System.Drawing` metadata check over the three generated files and compare the two runtime files with `Get-FileHash`. Expected: high-resolution `1024x1024`, runtime `192x192`, all `Format24bppRgb` or equivalent opaque RGB PNG, no corner with RGB values below `28`, and matching runtime hashes.

- [x] **Step 2: Check all configuration references**

Run:

```powershell
rg -n '\$media:app_icon|"icon"|"startWindowIcon"' AppScope/app.json5 entry/src/main/module.json5
```

Expected: the existing `$media:app_icon` references remain present; no new resource key is required.

### Task 3: Build the release product

**Files:**
- Read: `package.json`
- Read: `hvigorfile.ts`

- [x] **Step 1: Identify the existing release command**

Run `Get-Content package.json` and use the repository's existing `build` or `assemble` script; do not introduce a new build command.

- [x] **Step 2: Run the release build**

Run the identified release build command from `C:\Users\27363\Desktop\APP\WaterReminder` and expect exit code `0`, with no resource merge or ArkTS compilation errors.

- [x] **Step 3: Verify the generated build resource**

Search the release output for `app_icon.png` and verify the packaged copy has the same `192x192` metadata as the source runtime asset.
