# 水韵饮水记录 UI 高保真还原 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** 在 HarmonyOS ArkTS 应用中，以 `390 x 844 vp` 为基准还原参考图中的 14 个页面、弹层和底部 Tab，并保持饮水记录、目标、统计、成就、植物和设置真实可操作。

**Architecture:** 保留现有 service/repository/model 分层，新增一次性演示数据引导和纯函数展示数据层。页面使用共享的 ArkUI 页面外壳、玻璃卡片、顶部栏、设置行和底部导航；进度环、图表和植物使用专用组件自定义绘制，避免整页图片或绝对定位拼图。

**Tech Stack:** HarmonyOS 6 / API 22、ArkTS、ArkUI 声明式 UI、Preferences、现有 Hypium 测试、Hvigor。

**Constraints:** 工作区没有 Git 元数据，不能执行 commit；每个任务用测试/构建/截图作为检查点替代提交点。

## 文件地图

### 新建

- `entry/src/main/ets/common/DashboardData.ets`：首页和统计页共用的纯展示计算、默认值和边界处理。
- `entry/src/main/ets/common/DemoData.ets`：参考图对应的演示记录、向日葵和统计 fixture 构造器。
- `entry/src/main/ets/services/DemoDataService.ets`：只负责首次空数据初始化，调用已有服务写入演示数据。
- `entry/src/main/ets/components/AppBackground.ets`：页面雾化背景和装饰层。
- `entry/src/main/ets/components/GlassCard.ets`：白色半透明卡片容器。
- `entry/src/main/ets/components/PageHeader.ets`：返回按钮、标题、右侧操作和日期头部。
- `entry/src/main/ets/components/BottomNavigation.ets`：首页、统计、成就、设置四 Tab 的固定底栏。
- `entry/src/main/ets/components/SegmentedControl.ets`：统计页和设置页使用的分段控件。
- `entry/src/main/ets/components/SettingRow.ets`：带图标、辅助值、箭头或开关的统一设置行。

### 修改

- `entry/src/main/ets/common/Theme.ets`：增加 UI token、玻璃卡片色、边框色、阴影和字号/间距常量。
- `entry/src/main/ets/pages/MainPage.ets`：接入演示数据初始化、共享底栏和页面背景。
- `entry/src/main/ets/pages/HomePage.ets`：按参考图重排首页，接入新进度环、快速添加、记录列表和底部弹层。
- `entry/src/main/ets/pages/StatsPage.ets`：重排统计卡片、分段切换、周柱状图、时段分析和饮品构成。
- `entry/src/main/ets/pages/AchievementPage.ets`：重排连续天数、累计饮水、植物卡和成就列表。
- `entry/src/main/ets/pages/SettingsPage.ets`：重排设置分组、主题色、关于弹窗和跳转入口。
- `entry/src/main/ets/pages/ProfilePage.ets`：对齐个人资料表单和分段选择器。
- `entry/src/main/ets/pages/GoalSettingsPage.ets`：对齐目标数值卡、自动计算开关和公式说明。
- `entry/src/main/ets/pages/ReminderSettingsPage.ets`：对齐提醒开关、间隔、时段和模式卡。
- `entry/src/main/ets/pages/BeveragePage.ets`：对齐饮品管理列表和含水率开关。
- `entry/src/main/ets/pages/CupPage.ets`：对齐杯具新增表单和列表。
- `entry/src/main/ets/pages/PlantGardenPage.ets`：对齐植物花园主卡、成长阶段和提示。
- `entry/src/main/ets/pages/DataManagePage.ets`：对齐备份、恢复、重置三个数据卡。
- `entry/src/main/ets/components/WaterWaveProgress.ets`：改为参考图样式的蓝/绿环形进度组件，保持现有 props 兼容。
- `entry/src/main/ets/components/StatsBarChart.ets`：固定图表高度、基线和柱子比例，避免动态内容改变布局。
- `entry/src/main/ets/components/PlantView.ets`、`AchievementCard.ets`、`QuickAddButton.ets`、`DrinkRecordItem.ets`、`BeverageSelector.ets`、`AmountInputDialog.ets`：统一卡片、文字、交互反馈和 token 使用。
- `entry/src/main/ets/services/PreferencesService.ets`：保留用户空昵称和目标设置，同时为演示初始化提供无侵入的首次空数据判断。
- `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`：增加展示计算和演示数据的单元测试。

### Task 1: 先锁定展示计算和默认基线

**Files:**
- Create: `entry/src/main/ets/common/DashboardData.ets`
- Create: `entry/src/main/ets/common/DemoData.ets`
- Test: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: 写失败测试**

在现有 `describe('WaterReminderRules')` 中增加以下行为测试。测试先导入尚不存在的函数，因此应该以缺少导出或编译失败结束，而不是直接通过：

```ts
import { completionPercent, remainingGoalMl } from '../../../main/ets/common/DashboardData'
import { buildDemoRecords, buildDemoPlant } from '../../../main/ets/common/DemoData'

it('matchesReferenceDashboardNumbers', 0, (): void => {
  expect(completionPercent(850, 2200)).assertEqual(38)
  expect(remainingGoalMl(850, 2200)).assertEqual(1350)
  expect(completionPercent(2400, 2200)).assertEqual(100)
})

it('buildsReferenceDemoState', 0, (): void => {
  const records = buildDemoRecords(new Date('2026-08-04T12:00:00+08:00').getTime())
  expect(records.length).assertEqual(2)
  expect(records[0].amountMl + records[1].amountMl).assertEqual(850)

  const plant = buildDemoPlant(new Date('2026-08-04T12:00:00+08:00').getTime())
  expect(plant.species).assertEqual('sunflower')
  expect(plant.growthStage).assertEqual(1)
  expect(plant.waterReceived).assertEqual(3450)
})
```

- [ ] **Step 2: 运行测试确认失败**

运行 `hvigorw test`；若工程没有 `hvigorw` wrapper，运行已安装的 Hvigor CLI 对 `entry` ohosTest 任务，并记录第一个真实编译错误。预期失败原因是 `DashboardData.ets` 和 `DemoData.ets` 尚不存在。

- [ ] **Step 3: 实现最小纯函数和 fixture**

在 `DashboardData.ets` 中实现稳定边界：

```ts
export function completionPercent(currentMl: number, goalMl: number): number {
  if (!Number.isFinite(currentMl) || !Number.isFinite(goalMl) || goalMl <= 0) return 0
  return Math.min(Math.max(Math.round((currentMl / goalMl) * 100), 0), 100)
}

export function remainingGoalMl(currentMl: number, goalMl: number): number {
  if (!Number.isFinite(currentMl) || !Number.isFinite(goalMl)) return 0
  return Math.max(Math.round(goalMl - currentMl), 0)
}
```

在 `DemoData.ets` 中用本地时间构造两条 `DrinkRecord`（`05:56`/`600 ml`、`06:18`/`250 ml`）和一个 `sunflower` `Plant`（`growthStage: 1`、`waterReceived: 3450`），所有时间字段使用传入的 `now`，确保测试不依赖当前日期。

- [ ] **Step 4: 运行测试确认通过**

再次运行同一 ohosTest 任务，预期新增测试和原有规则测试全部通过；如果失败，只修正纯函数或 fixture，不修改页面。

## Task 2: 接入首次演示数据且不改变真实业务服务

**Files:**
- Create: `entry/src/main/ets/services/DemoDataService.ets`
- Modify: `entry/src/main/ets/pages/MainPage.ets`
- Modify: `entry/src/main/ets/services/PreferencesService.ets`

- [ ] **Step 1: 写初始化行为测试**

为 `DemoDataService` 暴露的纯判断函数增加测试：空的今日记录且 `profile.updatedAt === 0` 时需要初始化；已有记录或用户已经保存过资料时不能覆盖。测试名称分别为 `seedsOnlyEmptyFirstLaunch` 和 `preservesExistingUserData`。

- [ ] **Step 2: 运行测试确认失败**

运行 ohosTest，预期失败原因是初始化判断函数尚未导出。

- [ ] **Step 3: 实现初始化服务**

`DemoDataService.ensureSeeded()` 只在以下条件同时满足时执行：今日无记录、用户 profile 的 `updatedAt` 为 `0`、当前没有植物。执行顺序固定为：

1. 使用 `buildDemoRecords()` 返回的两条记录字段构造成 `DrinkRecordPayload`，再调用 `DrinkService.addRecord()`，这样仍由现有服务计算 hydration 值和写入时间字段。
2. 调用 `PlantService.createPlant('sunflower', '我的向日葵')`，再调用 `waterPlant(3450)`。
3. 保存 profile 的 `dailyGoalMl: 2200`、`isGoalAutoCalculated: true`、`onboardingCompleted: true`，不填昵称。
4. 调用 `AchievementService.checkAndUpdate(2200)`，让成就页显示可解释的进度。

`MainPage.aboutToAppear()` 在检查 onboarding 之前 `await new DemoDataService(getContext(this)).ensureSeeded()`，然后重新读取 profile。`PreferencesService` 只增加必要的 profile 保存/读取兼容，不改动默认 profile 字段语义。

- [ ] **Step 4: 运行测试和构建**

运行 ohosTest；再运行 `hvigorw assembleHap` 或工程实际可用的 Hvigor assemble 任务。预期测试通过，构建不新增 ArkTS 类型错误。

## Task 3: 建立共享视觉 token 和 ArkUI 基础组件

**Files:**
- Modify: `entry/src/main/ets/common/Theme.ets`
- Create: `entry/src/main/ets/components/AppBackground.ets`
- Create: `entry/src/main/ets/components/GlassCard.ets`
- Create: `entry/src/main/ets/components/PageHeader.ets`
- Create: `entry/src/main/ets/components/BottomNavigation.ets`
- Create: `entry/src/main/ets/components/SegmentedControl.ets`
- Create: `entry/src/main/ets/components/SettingRow.ets`

- [ ] **Step 1: 写组件契约测试/静态检查基线**

为 `Theme.ets` 增加纯 token 断言：蓝色主题主色为 `#39B7F4`，卡片圆角为 `24`，页面水平内边距为 `20`，底栏高度为 `72`。这些断言放入现有规则测试，确保视觉常量不是散落魔法值。

- [ ] **Step 2: 运行测试确认失败**

运行 ohosTest，预期失败原因是 token 未定义或值仍是旧主题。

- [ ] **Step 3: 实现 token 和共享组件**

在 `Theme.ets` 增加以下稳定常量，并让现有 `ThemeColors` 继续提供主题色：

```ts
export const UiTokens = {
  pageHorizontal: 20,
  cardRadius: 24,
  smallRadius: 14,
  bottomBarHeight: 72,
  sectionGap: 14,
  cardPadding: 16,
  primaryBlue: '#39B7F4',
  textPrimary: '#172A40',
  textSecondary: '#718398',
  background: '#F4FAFF',
  glassBorder: '#FFFFFFCC'
}
```

`GlassCard` 接收 `radius`、`padding`、`content`，统一白色背景、透明边框和阴影；`PageHeader` 接收 `title`、`showBack`、`actionText`、`onBack`、`onAction`；`BottomNavigation` 接收 `selectedIndex` 和 `onChange`，固定高度且不让标签内容撑开布局；`SegmentedControl` 接收标签数组和选中下标；`SettingRow` 接收 icon、title、value、showArrow、toggleValue 和 action；`AppBackground` 提供背景色和低对比度装饰层。

- [ ] **Step 4: 运行测试和空壳构建**

运行 ohosTest 和 Hvigor assemble。预期 token 测试通过，新增组件可以被编译但尚未替换旧页面。

## Task 4: 还原主框架和首页交互

**Files:**
- Modify: `entry/src/main/ets/pages/MainPage.ets`
- Modify: `entry/src/main/ets/pages/HomePage.ets`
- Modify: `entry/src/main/ets/components/WaterWaveProgress.ets`
- Modify: `entry/src/main/ets/components/QuickAddButton.ets`
- Modify: `entry/src/main/ets/components/DrinkRecordItem.ets`
- Modify: `entry/src/main/ets/components/BeverageSelector.ets`
- Modify: `entry/src/main/ets/components/AmountInputDialog.ets`

- [ ] **Step 1: 用组件测试锁定首页交互数据**

保留并补充以下行为断言：快速添加 `250 ml` 后记录 payload 的 beverageId 为当前饮品，进度从 `850/2200` 变为 `1100/2200`，撤销后恢复 `850/2200`。这些断言调用现有 `DrinkService` 和 `WaterReminderRules`，不测试组件内部布局。

- [ ] **Step 2: 运行测试确认新断言失败**

运行 ohosTest，预期失败点是新首页状态的派生值或尚未接入的演示数据。

- [ ] **Step 3: 重写首页布局并保留现有业务调用**

将 `HomePage.build()` 调整为：页面背景 -> 顶部日期/日历入口 -> `WaterWaveProgress` -> 剩余目标文本 -> 四个快速添加卡 -> 自定义按钮 -> 当前饮品行 -> 今日记录卡 -> 底部安全区。进度组件保留现有 props，改用 `Gauge` 叠加水滴装饰和稳定中心文本，`progress` 使用 `completionPercent()`。

`MainPage` 使用 `AppBackground` 和 `BottomNavigation`，Tab 仍渲染现有四个页面；首页所有新增、撤销、饮品选择和自定义输入回调沿用 `DrinkService`、`PlantService`、`AchievementService` 和 `ReminderService`。

- [ ] **Step 4: 运行测试、构建并截图首页**

在模拟器 `390 x 844 vp` 下截图首页、饮品选择弹层、自定义输入弹层和撤销提示。检查环形进度中心、四个快捷卡、记录卡和底栏没有重叠或横向溢出。

## Task 5: 还原统计和成就页面

**Files:**
- Modify: `entry/src/main/ets/pages/StatsPage.ets`
- Modify: `entry/src/main/ets/pages/AchievementPage.ets`
- Modify: `entry/src/main/ets/components/StatsBarChart.ets`
- Modify: `entry/src/main/ets/components/AchievementCard.ets`
- Modify: `entry/src/main/ets/components/PlantView.ets`

- [ ] **Step 1: 写统计和成就派生数据测试**

增加以下断言：本周 7 天数据固定有 4 天达到目标时 `goalDays === 4`；饮品构成合计等于当期 hydration；成就页的 `12` 连续天数、`3.45 L` 累计饮水和向日葵阶段读取自服务结果而不是硬编码在页面 build 中。

- [ ] **Step 2: 运行测试确认失败**

运行 ohosTest，预期失败原因是新的 fixture 映射或组件输入尚未完成。

- [ ] **Step 3: 实现页面和图表**

统计页按参考图顺序组织：顶部标题、`本周/本月/本年` 分段、总量卡、固定高度柱状图、`达标天数/日均饮水` 摘要卡、时段分析卡、饮品构成卡。图表柱子用 `Math.min(1, hydrationMl / goalMl)`，固定图表高度 `132 vp`，标签单独占位。

成就页组织为两个顶部指标卡、植物成长卡和成就列表。`PlantView` 使用固定宽高和阶段图标，避免 emoji/图形加载造成布局跳动；成就卡显示已解锁勾选态和进度条。

- [ ] **Step 4: 构建并截图验证**

运行测试和 assemble；在模拟器截图统计和成就两页，验证分段切换后布局尺寸不变，长列表可以滚动到底，底部导航仍可点击。

## Task 6: 还原设置页与设置流

**Files:**
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`
- Modify: `entry/src/main/ets/pages/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/GoalSettingsPage.ets`
- Modify: `entry/src/main/ets/pages/ReminderSettingsPage.ets`
- Modify: `entry/src/main/ets/pages/BeveragePage.ets`
- Modify: `entry/src/main/ets/pages/CupPage.ets`

- [ ] **Step 1: 写设置保存行为测试**

补充测试覆盖：修改每日目标保存为 `2200`、切换主题色保存为 `green`、提醒间隔保存为 `60` 分钟、增加 `250 ml` 杯具后能从 `getCups()` 读回。测试调用现有 Preferences/模型纯逻辑，页面只负责触发它们。

- [ ] **Step 2: 运行测试确认失败**

运行 ohosTest，预期失败原因是新页面表单状态尚未按统一字段保存。

- [ ] **Step 3: 按参考图重排设置流**

`SettingsPage` 使用四组白色卡片分组和主题色圆点；每行使用 `SettingRow`，个人入口显示圆形头像和 `未设置昵称`。详情页顶部使用 `PageHeader`，页面内容使用 `GlassCard`，保存按钮固定在对应卡片内部或顶部右侧。

保持现有路由：`ProfilePage` -> `GoalSettingsPage` -> `ReminderSettingsPage`、`BeveragePage`、`CupPage`，所有表单保存后调用现有 service 并在 `onPageShow` 刷新。

- [ ] **Step 4: 构建并逐页验证设置跳转**

运行测试和 assemble；逐个点击设置页入口，验证返回、保存、主题色和深色模式不会丢失状态，`390 x 844 vp` 下输入框、分段控件和按钮没有被底部系统区域遮挡。

## Task 7: 还原扩展页、数据管理和关于弹窗

**Files:**
- Modify: `entry/src/main/ets/pages/PlantGardenPage.ets`
- Modify: `entry/src/main/ets/pages/DataManagePage.ets`
- Modify: `entry/src/main/ets/pages/RecordDetailPage.ets`
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`

- [ ] **Step 1: 写备份/恢复/重置行为测试**

增加测试：备份输出包含 records、profile、settings、cups、plants、achievements；恢复一个包含 `250 ml` 记录的 JSON 后记录可读取；重置后存储回到默认配置。测试只覆盖现有 `BackupService`/repository 业务，不依赖页面。

- [ ] **Step 2: 运行测试确认失败**

运行 ohosTest，先记录现有备份结构和失败差异，再实现 UI 需要的输出/导入反馈。

- [ ] **Step 3: 实现扩展页**

植物花园使用浅黄植物背景、向日葵主卡、阶段横向列表和成长提示；数据管理使用蓝色备份、绿色恢复、红色重置三张卡；记录详情使用统一顶部栏和保存/删除操作；设置页的关于入口打开居中白色弹窗，包含水滴图形、版本文案和确认按钮。

- [ ] **Step 4: 构建并验证所有扩展入口**

运行测试和 assemble；从设置页进入植物花园、数据管理、饮品管理和杯具管理，完成一次备份/恢复/重置，关闭关于弹窗后回到原页面状态。

## Task 8: 全量回归和截图验收

**Files:**
- Modify only files identified by failing verification; do not perform unrelated refactors.
- Verification artifacts: local simulator screenshots for all reference states.

- [ ] **Step 1: 运行完整测试和构建**

运行 ohosTest 全量任务，再运行 Hvigor assemble。预期所有测试通过且生成可安装 HAP；如果命令名因本机 SDK wrapper 不同，以工程中实际可用的 Hvigor 任务为准，并记录命令和输出。

- [ ] **Step 2: 逐页截图**

按顺序截图：首页、首页自定义输入、饮品选择、统计、成就、设置、个人资料、饮水目标、提醒设置、饮品管理、杯具管理、植物花园、数据管理、关于弹窗。每张图使用 `390 x 844 vp`，等待页面完成渲染后再截图。

- [ ] **Step 3: 按优先级修正视觉差异**

先修正会影响整体观感的页面宽度、高度、顶部/底部安全区、卡片位置和字号；再修正颜色、边框、阴影和图标；最后修正文案、微小间距和交互反馈。每次修正后至少重跑受影响页面和全量构建。

- [ ] **Step 4: 完成收尾检查**

确认没有 `TODO`/`TBD`、没有新增编译警告、没有页面文字溢出、没有无法点击的可操作控件、没有破坏现有规则测试，并记录工作区变更文件。由于无 Git 仓库，不执行 commit。
