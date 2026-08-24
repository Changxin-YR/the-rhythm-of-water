# 元气有数 Apple 风格 HarmonyOS UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建可复用的 Apple 风格鸿蒙 UI 技能，并把元气有数的生产界面统一为克制、清晰、可验证的 Apple 式设计语言。

**Architecture:** 保留现有 ArkTS 页面、服务、仓储、数据库和路由。视觉变化从 `Theme.ets`、系统符号映射和共享组件向下传播；账本继续保留自身模块边界，但其语义色与主应用统一。

**Tech Stack:** ArkTS、ArkUI、HarmonyOS API 22、Hypium、PowerShell、Hvigor、HDC。

---

### Task 1: 创建并验证专用技能

**Files:**
- Create: `C:/Users/27363/.codex/skills/harmonyos-apple-ui/SKILL.md`
- Create: `C:/Users/27363/.codex/skills/harmonyos-apple-ui/agents/openai.yaml`
- Create: `C:/Users/27363/.codex/skills/harmonyos-apple-ui/references/design-system.md`
- Create: `C:/Users/27363/.codex/skills/harmonyos-apple-ui/references/arkui-checklist.md`

- [ ] **Step 1: 初始化技能**

Run the official `skill-creator` initializer with only the required `references` resource directory and interface metadata.

- [ ] **Step 2: 写入精简工作流**

`SKILL.md` 必须规定以下优先级：Huawei 强制要求、无障碍与系统行为、Apple HIG、项目品牌；并要求先查现有主题和共享组件，不直接在页面内堆颜色和尺寸。

- [ ] **Step 3: 写入两份参考**

`design-system.md` 固定语义色、排版、间距、圆角、材质和动效原则。`arkui-checklist.md` 固定 `SymbolGlyph`、安全区、状态栏、深色模式、48vp/40vp 命中区和运行时证据要求。

- [ ] **Step 4: 验证技能结构**

Run:

```powershell
python C:\Users\27363\.codex\skills\.system\skill-creator\scripts\quick_validate.py C:\Users\27363\.codex\skills\harmonyos-apple-ui
```

Expected: validation exits `0`.

### Task 2: 建立 Apple 风格静态契约和主题 token

**Files:**
- Create: `tools/verify_apple_ui_contract.ps1`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`
- Modify: `entry/src/main/ets/common/Theme.ets`
- Modify: `entry/src/main/ets/ledger/common/LedgerTheme.ets`

- [ ] **Step 1: 写入失败契约**

静态检查必须断言：

```powershell
$theme.Contains('cardRadius: 16')
$theme.Contains('bottomBarHeight: 64')
$mainPage.Contains("sys.symbol.drop_fill")
$appBackground -notmatch '\.blur\('
$glassCard -notmatch '\.shadow\('
```

并扫描生产 UI 文件中的 Unicode Emoji；模型持久化字段可保留，但页面和组件不得直接渲染硬编码 Emoji。

- [ ] **Step 2: 更新 Hypium 视觉 token 期望并确认 RED**

```ets
expect(UiTokens.primaryBlue).assertEqual('#007AFF')
expect(UiTokens.cardRadius).assertEqual(16)
expect(UiTokens.bottomBarHeight).assertEqual(64)
expect(UiTokens.recommendedTouchTargetSize).assertEqual(48)
expect(UiTokens.minimumTouchTargetSize).assertEqual(40)
```

Run the ohosTest build. Expected: token assertions fail against the old theme.

- [ ] **Step 3: 实现统一语义色**

Light baseline:

```ets
primary: '#007AFF'
accent: '#30B0C7'
background: '#F2F2F7'
card: '#FFFFFF'
surface: '#E9E9EE'
divider: '#C6C6C8'
success: '#248A3D'
danger: '#D70015'
```

Dark baseline:

```ets
primary: '#0A84FF'
accent: '#64D2FF'
background: '#000000'
card: '#1C1C1E'
surface: '#2C2C2E'
divider: '#38383A'
success: '#30D158'
danger: '#FF453A'
```

账本的 `ledgerColor()` 映射到同一中性表面，收入/支出继续使用成功/危险语义色，不再以紫蓝渐变作为默认大面积背景。

- [ ] **Step 4: 运行 token 与对比度检查**

Run the static contract and ohosTest build. Expected: token、对比度和 48vp/40vp 契约通过。

### Task 3: 统一系统图标和共享组件

**Files:**
- Create: `entry/src/main/ets/components/AppSymbol.ets`
- Modify: `entry/src/main/ets/components/AppBackground.ets`
- Modify: `entry/src/main/ets/components/GlassCard.ets`
- Modify: `entry/src/main/ets/components/PageHeader.ets`
- Modify: `entry/src/main/ets/components/QuickAddButton.ets`
- Modify: `entry/src/main/ets/components/WaterWaveProgress.ets`
- Modify: `entry/src/main/ets/components/DrinkRecordItem.ets`
- Modify: `entry/src/main/ets/components/AchievementCard.ets`

- [ ] **Step 1: 建立系统符号映射**

`AppSymbol` 接收稳定语义名或旧 Emoji 字符串，并返回已在本机 SDK 22 中确认存在的资源，例如：

```ets
'water' -> $r('sys.symbol.drop_fill')
'wallet' -> $r('sys.symbol.wallet_fill')
'achievement' -> $r('sys.symbol.medal')
'plant' -> $r('sys.symbol.leaf_fill')
'settings' -> $r('sys.symbol.gearshape')
'next' -> $r('sys.symbol.chevron_right')
```

未知或用户自定义值回退到 `star`，不修改存储内容。

- [ ] **Step 2: 简化基础表面**

`AppBackground` 只绘制语义背景。`GlassCard` 默认无边框、无阴影，圆角使用 `UiTokens.cardRadius`。必要分隔使用页面自身的 `Divider`。

- [ ] **Step 3: 改造标题、按钮和进度**

`PageHeader` 使用 `chevron_left`、`plus` 系统符号和 48vp 命中区。`QuickAddButton` 使用水滴符号、0.98 按压缩放和 140ms 反馈。`WaterWaveProgress` 删除顶部 Emoji，仅保留环形进度和数值层级。

- [ ] **Step 4: 改造记录与成就行**

`DrinkRecordItem` 和 `AchievementCard` 使用 `AppSymbol`，删除默认阴影与重复边框，并保持删除、点击、进度和解锁逻辑不变。

- [ ] **Step 5: 运行静态契约与 release 编译检查**

Expected: 共享组件中没有硬编码 Emoji、装饰 blur 或默认发光 shadow，ArkTS 编译成功。

### Task 4: 改造主壳、四个主标签和账本首页

**Files:**
- Modify: `entry/src/main/ets/pages/MainPage.ets`
- Modify: `entry/src/main/ets/pages/OverviewPage.ets`
- Modify: `entry/src/main/ets/pages/WaterHubPage.ets`
- Modify: `entry/src/main/ets/pages/HomePage.ets`
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`
- Modify: `entry/src/main/ets/ledger/pages/LedgerHomePage.ets`
- Modify: `entry/src/main/ets/ledger/components/SummaryCard.ets`
- Modify: `entry/src/main/ets/ledger/components/BillCard.ets`

- [ ] **Step 1: 改造底部导航**

四个标签使用 `square_grid_2x2`、`drop_fill`、`wallet_fill`、`person`。底栏内容高度 64vp，加实际系统底部 inset；选中态使用语义色和 180ms 轻微缩放，非选中态保持中性。

- [ ] **Step 2: 改造概览与喝水页**

概览保留两块主摘要和最近活动，取消每块默认边框。喝水页把“统计/成就”改为系统图标动作；圆形进度、快捷容量和记录列表使用共享组件，不改变添加、撤销、删除和饮品切换。

- [ ] **Step 3: 改造我的页面**

资料入口、健康、财务、数据与隐私分组改为 iOS 式 grouped list；行尾统一 `chevron_right`，主题色仍可选择，所有行保持至少 48vp。

- [ ] **Step 4: 改造账本首页**

保留账本页面内视图和数据服务；余额摘要改为中性表面，收入/支出只在数值与小型状态标记上着色。移除主按钮渐变和卡片阴影，列表使用细分隔线。

- [ ] **Step 5: 运行回归检查**

Run all PowerShell contracts and release build. Expected: existing路由、安全区、对比度和数据契约继续通过。

### Task 5: 清理代表子页面并完成设备验收

**Files:**
- Modify: `entry/src/main/ets/pages/AchievementPage.ets`
- Modify: `entry/src/main/ets/pages/BeveragePage.ets`
- Modify: `entry/src/main/ets/pages/PlantGardenPage.ets`
- Modify: `entry/src/main/ets/pages/StatsPage.ets`
- Modify: `entry/src/main/ets/pages/OnboardingPage.ets`
- Modify: `entry/src/main/ets/components/PlantView.ets`
- Modify: `entry/src/main/ets/components/BeverageSelector.ets`
- Modify: `entry/src/main/ets/pages/GoalSettingsPage.ets`
- Modify: `entry/src/main/ets/pages/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/DataManagePage.ets`
- Modify: `entry/src/main/ets/pages/RecordDetailPage.ets`
- Modify: `entry/src/main/ets/pages/ProtocolPage.ets`
- Modify: `entry/src/main/ets/ledger/pages/LedgerAddBillPage.ets`
- Modify: `entry/src/main/ets/ledger/pages/LedgerEditBillPage.ets`
- Modify: `entry/src/main/ets/ledger/pages/LedgerBudgetPage.ets`
- Modify: `entry/src/main/ets/ledger/pages/LedgerCategoryManagePage.ets`
- Modify: `entry/src/main/ets/ledger/pages/LedgerStatisticsPage.ets`
- Create: `device-evidence/apple-ui-2026-08-17-*.png`
- Create: `docs/apple-ui-verification-2026-08-17.md`

- [ ] **Step 1: 清除生产 UI 的剩余硬编码 Emoji**

成就、饮品、植物、统计空状态和引导页通过 `AppSymbol` 映射。模型、数据库和备份中的旧字符保留以兼容现有用户数据。

- [ ] **Step 2: 运行所有静态检查**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_apple_ui_contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_harmony_review_checklist.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_ui_repair_contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_scroll_content_top_alignment.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_reset_all_data_contract.ps1
```

Expected: every script exits `0`.

- [ ] **Step 3: 构建与运行测试**

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@ohosTest -p product=default --no-daemon
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=release --no-daemon
```

Expected: both builds exit `0`; install and run `OpenHarmonyTestRunner` when the API 22 emulator is available, with zero failures and zero errors.

- [ ] **Step 4: 视觉验收**

在手机模拟器上捕获浅色/深色的概览、喝水、账本、我的、一个子页面和一个弹窗。检查状态栏、底部系统区、长文字、滚动末端和键盘状态；平板、横屏或多窗不可用时标记 `unverified`。

- [ ] **Step 5: 写入验证报告**

报告列出实际命令、退出码、测试计数、截图路径和未验证设备状态，不以编译成功替代运行时视觉结论。

## Repository Note

This directory has no `.git` metadata. Commit steps are intentionally replaced by explicit verification checkpoints and evidence artifacts.
