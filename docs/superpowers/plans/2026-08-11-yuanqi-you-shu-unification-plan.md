# 元气有数深度融合实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 SDK 22、纯单机约束下，将 WaterReminder 与 JiZhangBen 的功能统一到“元气有数”四项导航中，并完成安全区、全局刷新、浅深色完整适配与排查表回归验证。

**Architecture:** 以 `WaterReminder` 为唯一构建工程，保留现有饮水服务和 `entry/src/main/ets/ledger` 账本域，新增只读概览聚合层和统一刷新总线；页面只消费语义主题令牌，不直接使用固定浅色/深色；旧 JiZhangBen 通过 CSV 适配器导入，统一备份使用版本化 JSON。

**Tech Stack:** HarmonyOS ArkTS/ArkUI、SDK 6.0.2(22)、Preferences、RelationalStore、Hypium、Hvigor、PowerShell 静态审计。

---

## 文件地图

- Create: `entry/src/main/ets/pages/OverviewPage.ets`，概览聚合页，独立读取饮水和账本摘要并分别降级。
- Create: `entry/src/main/ets/pages/WaterHubPage.ets`，喝水一级入口，承载 Home、统计、成就、提醒、饮品和植物入口。
- Create: `entry/src/main/ets/pages/ProtocolPage.ets`，本地用户协议、隐私说明、数据与提醒限制。
- Create: `entry/src/main/ets/common/OverviewData.ets`，概览显示模型和金额/百分比格式化纯函数。
- Create: `entry/src/main/ets/services/LedgerRefreshBridge.ets`，把账本 `DataChangeNotifier` 桥接到应用级刷新信号。
- Modify: `entry/src/main/ets/common/DataRefresh.ets`，统一单调递增刷新版本，删除各页面直接写 `Date.now()` 的路径。
- Modify: `entry/src/main/ets/pages/MainPage.ets`，改为“概览/喝水/账本/我的”四项导航，保留安全区 inset 和主题切换。
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`，改为“我的”设置分组，合并健康、财务、外观、数据、协议入口。
- Modify: `entry/src/main/ets/common/Theme.ets`、`entry/src/main/ets/common/SystemBarAppearance.ets`、`entry/src/main/ets/services/SystemBarService.ets`，补齐语义色和安全区主题。
- Modify: `entry/src/main/ets/ledger/common/DataChangeNotifier.ets`、`entry/src/main/ets/ledger/services/BillService.ets`、`entry/src/main/ets/ledger/services/CategoryService.ets`，桥接账本刷新。
- Modify: `entry/src/main/ets/services/BackupService.ets`、`entry/src/main/ets/common/BackupRules.ets`，增加账本 JSON 备份和完整校验。
- Create: `entry/src/main/ets/services/LedgerCsvMigrationService.ets`，解析 JiZhangBen 按月 CSV，输出预览和可提交的账单集合。
- Modify: `entry/src/main/ets/pages/DataManagePage.ets`，增加 CSV/统一 JSON 导入预览、确认和失败回滚提示。
- Modify: `entry/src/main/resources/base/element/string.json`、`entry/src/main/resources/base/profile/main_pages.json`、`entry/src/main/ets/common/Routes.ets`，统一“元气有数”展示文案和页面路由。
- Modify: `entry/src/main/ets/pages`、`entry/src/main/ets/components`、`entry/src/main/ets/ledger` 下所有主题消费页面，移除不安全的 `Color.White` 和浅色表面硬编码。
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`、`entry/src/ohosTest/ets/test/LedgerRules.test.ets`、`entry/src/ohosTest/ets/test/List.test.ets`，增加刷新、概览、迁移和主题契约测试。
- Modify: `tools/verify_harmony_review_checklist.ps1`，增加 SDK 22、无网络权限、刷新信号和硬编码中性色审计。

## Task 1: 建立 SDK 22、离线和刷新总线契约

**Files:**
- Modify: `entry/src/main/ets/common/DataRefresh.ets`
- Create: `entry/src/main/ets/services/LedgerRefreshBridge.ets`
- Modify: `entry/src/main/ets/ledger/common/DataChangeNotifier.ets`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`
- Modify: `entry/src/ohosTest/ets/test/LedgerRules.test.ets`

- [ ] **Step 1: 写失败测试，固定刷新版本和桥接行为。**

```ts
import { nextRefreshRevision } from '../../../main/ets/common/DataRefresh'

it('keepsRefreshRevisionMonotonic', 0, (): void => {
  expect(nextRefreshRevision(0)).assertEqual(1)
  expect(nextRefreshRevision(41)).assertEqual(42)
  expect(nextRefreshRevision(-1)).assertEqual(1)
})
```

在 `LedgerRules.test.ets` 增加：账单新增、删除和分类变更都调用桥接回调一次，桥接回调只递增 `refreshSignal`。

- [ ] **Step 2: 运行现有 Hypium 任务确认新增契约失败。**

运行：`hvigorw.bat test`；若本机 wrapper 不在 PATH，使用 DevEco Studio 的 Hvigor CLI 执行同一 `entry:ohosTest` 任务。预期：新增导出或桥接函数缺失导致失败。

- [ ] **Step 3: 实现单调递增发布器和账本桥接器。**

`DataRefresh.ets` 保留并导出以下接口：

```ts
export function nextRefreshRevision(current: number | undefined): number {
  if (current === undefined || !Number.isFinite(current) || current < 0) return 1
  return Math.floor(current) + 1
}

export function publishDataRefresh(): void {
  const current = AppStorage.get<number>('refreshSignal')
  AppStorage.setOrCreate('refreshSignal', nextRefreshRevision(current))
}
```

`LedgerRefreshBridge` 订阅 `DataChangeNotifier`，收到 `BillChanged` 或 `CategoryChanged` 后调用 `publishDataRefresh()`；所有页面删除直接写 `Date.now()` 的刷新代码。

- [ ] **Step 4: 重新运行测试并确认 SDK/权限静态约束。**

运行 `& '.\tools\verify_harmony_review_checklist.ps1'`。预期新增刷新检查通过，`build-profile.json5` 仍为 `compatibleSdkVersion/targetSdkVersion = 6.0.2(22)`，`module.json5` 只保留提醒和振动权限。

## Task 2: 统一四项主导航和概览入口

**Files:**
- Create: `entry/src/main/ets/common/OverviewData.ets`
- Create: `entry/src/main/ets/pages/OverviewPage.ets`
- Create: `entry/src/main/ets/pages/WaterHubPage.ets`
- Modify: `entry/src/main/ets/pages/MainPage.ets`
- Modify: `entry/src/main/ets/common/Routes.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`

- [ ] **Step 1: 写概览纯函数失败测试。**

```ts
import { completionPercent, formatBalance } from '../../../main/ets/common/OverviewData'

it('buildsOverviewProgressWithoutOverflow', 0, (): void => {
  expect(completionPercent(500, 1000)).assertEqual(50)
  expect(completionPercent(1200, 1000)).assertEqual(100)
  expect(completionPercent(0, 0)).assertEqual(0)
})

it('formatsPositiveAndNegativeBalance', 0, (): void => {
  expect(formatBalance(12.5)).assertEqual('¥12.50')
  expect(formatBalance(-3)).assertEqual('-¥3.00')
})
```

- [ ] **Step 2: 实现概览数据模型和独立加载。**

`OverviewPage` 使用 `DrinkService.getTodaySummary()`、`DrinkService.getStreak()`、`StatisticsService.getMonthSummary()`；两组请求分别包在 `try/catch` 中，饮水失败只显示饮水错误状态，账本失败只显示账本错误状态。组件订阅 `refreshSignal` 和 `colorMode`，每次变化重新加载数据和主题。

- [ ] **Step 3: 实现四项导航。**

`MainPage` 的 `tabItems` 固定为：

```ts
private tabItems: TabItem[] = [
  { label: '概览' },
  { label: '喝水' },
  { label: '账本' },
  { label: '我的' }
]
```

四个内容分别渲染 `OverviewPage`、`WaterHubPage`、`LedgerHomePage`、`SettingsPage`；底栏使用 `safeAreaBottom` 计算出的 inset，页面主体使用 `safeAreaTop`，不允许内容进入系统安全区。

- [ ] **Step 4: 接入快捷操作和二级页面。**

概览中的“记录饮水”打开 Home 的记录流程，“记一笔”打开 `entry/src/main/ets/ledger/pages/LedgerAddBillPage.ets`；`WaterHubPage` 提供统计、成就、提醒、饮品、植物和目标入口，账本页提供账单、预算、分类和统计入口。

- [ ] **Step 5: 运行测试并构建调试 HAP。**

预期概览纯函数测试通过，四项导航无 ArkTS 类型错误，HAP 输出到 `entry/build/default/outputs/default/entry-default-signed.hap`。

## Task 3: 重组“我的”、协议和数据管理

**Files:**
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`
- Create: `entry/src/main/ets/pages/ProtocolPage.ets`
- Modify: `entry/src/main/ets/pages/DataManagePage.ets`
- Modify: `entry/src/main/resources/base/element/string.json`
- Modify: `entry/src/main/ets/common/Routes.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

- [ ] **Step 1: 建立设置分组契约。**

设置页面必须按以下顺序输出入口：健康管理、财务管理、外观、数据与隐私、关于与协议；旧的重复“数据管理”“随机账本”和旧产品名称不再暴露。

- [ ] **Step 2: 实现协议页本地内容。**

`ProtocolPage` 只渲染本地静态文本，包含产品用途、本地存储、提醒能力限制、CSV/JSON 导入导出、重置不可恢复、反馈方式和版本信息，不调用网络 API。

- [ ] **Step 3: 将数据管理入口接到统一备份和迁移。**

导出全部数据显示 JSON；旧账本导入显示 CSV；重置前显示饮水、账本、设置、成就都会清除，并使用 `ThemedConfirmDialog` 二次确认。

- [ ] **Step 4: 运行路由和文案审计。**

运行：`rg -n "随机账本|关于补水啦|关于|数据管理" entry/src/main/ets entry/src/main/resources`。预期仅保留统一“元气有数”的关于与协议入口及内部兼容路由。

## Task 4: 完整深色语义色和安全区主题

**Files:**
- Modify: `entry/src/main/ets/common/Theme.ets`
- Modify: `entry/src/main/ets/common/SystemBarAppearance.ets`
- Modify: `entry/src/main/ets/services/SystemBarService.ets`
- Modify: `entry/src/main/ets/components/SystemSafeAreaBackground.ets`
- Modify: all theme-consuming files under `entry/src/main/ets/pages`, `entry/src/main/ets/components`, and `entry/src/main/ets/ledger`
- Modify: `entry/src/ohosTest/ets/test/WaterReminderRules.test.ets`
- Modify: `tools/verify_harmony_review_checklist.ps1`

- [ ] **Step 1: 写浅深色和系统栏失败测试。**

断言 `getThemeColors(true, 'blue')` 的 `background/card/input/divider/systemBar` 都不同于浅色值；断言深色 `systemBarContent` 为浅色且浅色 `systemBarContent` 为深色。

- [ ] **Step 2: 实现完整语义令牌。**

令牌至少覆盖 `background/card/surface/input/divider/progressTrack/selectedSurface/positiveSurface/danger/dialogOverlay/systemBar/systemBarContent/textPrimary/textSecondary/primary/primaryText/water/income/expense/inactive`；六个主题色都为浅色和深色定义可读前景。

- [ ] **Step 3: 清除硬编码中性色。**

把 `Color.White`、浅灰卡片、浅色分割线、白色弹层和白色按钮文字改成页面传入的语义色；按钮文字使用 `primaryText` 或专用 `onPrimary`，不因深色主题再次变成白底白字。图表、空状态、开关、选中/禁用/错误/成功态都从主题令牌取色。

- [ ] **Step 4: 让安全区颜色随主题刷新。**

`SystemSafeAreaBackground`、状态栏和导航栏都接收同一份 `ThemeColors`；主题切换时同时刷新页面背景、底部导航、安全区和系统栏图标明暗。

- [ ] **Step 5: 运行静态和纯函数审计。**

运行 `rg -n "Color\.White|#FFFFFF|#F0F0F0|#F5F7F8|#E0E0E0" entry/src/main/ets/pages entry/src/main/ets/components entry/src/main/ets/ledger`，预期无未注明的主题表面硬编码；随后运行完整 Hypium。

## Task 5: 统一 JSON 备份与 JiZhangBen CSV 迁移

**Files:**
- Create: `entry/src/main/ets/services/LedgerCsvMigrationService.ets`
- Modify: `entry/src/main/ets/services/BackupService.ets`
- Modify: `entry/src/main/ets/common/BackupRules.ets`
- Modify: `entry/src/main/ets/pages/DataManagePage.ets`
- Modify: `entry/src/ohosTest/ets/test/LedgerRules.test.ets`

- [ ] **Step 1: 写 CSV 解析和去重失败测试。**

测试包含 UTF-8 BOM、带逗号备注、收入/支出类型、未知分类、重复行和非法金额；未知分类映射 `其他`，重复行按日期/金额/类型/备注/分类生成稳定指纹并只保留一条。

- [ ] **Step 2: 实现 `LedgerCsvMigrationService`。**

公开 `preview(csv: string): MigrationPreview` 和 `commit(preview: MigrationPreview): Promise<MigrationResult>`；`preview` 不写数据库，只返回新增、覆盖、跳过和错误记录；`commit` 在所有行验证通过且用户确认后调用 `BillService`/数据库事务写入。

- [ ] **Step 3: 扩展 JSON 备份。**

在现有 `BackupData` 中增加 `ledger.bills`、`ledger.categories`、`ledger.budgets`、`ledger.metadata`，校验通过后先缓存全部目标数据，再一次性写入；任何失败都恢复原快照且不发布刷新信号。

- [ ] **Step 4: 保留按月 CSV 导出。**

在“账本 > 数据导出”保留 JiZhangBen 的按月 CSV 导出字段：日期、类型、分类、金额、备注；统一 JSON 导出作为完整备份，不替代单月 CSV 分享。

- [ ] **Step 5: 运行迁移单元测试和回滚测试。**

预期合法 CSV 导入成功，非法 CSV 不改已有账单，重复导入不重复写入，统一 JSON 失败不产生部分数据。

## Task 6: 跨域同步和交互回归

**Files:**
- Modify: `entry/src/main/ets/pages/HomePage.ets`
- Modify: `entry/src/main/ets/pages/RecordDetailPage.ets`
- Modify: `entry/src/main/ets/pages/BeveragePage.ets`
- Modify: `entry/src/main/ets/pages/GoalSettingsPage.ets`
- Modify: `entry/src/main/ets/pages/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`
- Modify: `entry/src/main/ets/pages/DataManagePage.ets`
- Modify: `entry/src/main/ets/ledger/pages/LedgerHomePage.ets`
- Modify: `entry/src/main/ets/ledger/pages/LedgerAddBillPage.ets`
- Modify: `entry/src/main/ets/ledger/pages/LedgerEditBillPage.ets`
- Modify: `entry/src/main/ets/ledger/pages/LedgerCategoryManagePage.ets`

- [ ] **Step 1: 将所有成功写操作接到刷新总线。**

饮水新增/撤销/删除、饮品启用/停用/编辑、目标保存、资料保存、主题保存、账单新增/编辑/删除、分类/预算变更、导入/恢复和重置都在持久化成功后调用 `publishDataRefresh()`；不再直接写 `Date.now()`。

- [ ] **Step 2: 让所有一级和二级页面监听刷新信号。**

页面的 `onRefreshSignal()` 必须重新读取本页面依赖的数据和主题；`OverviewPage` 同时重读饮水与账本摘要，`LedgerHomePage` 保留本地通知但也监听全局信号。

- [ ] **Step 3: 验证不切页同步。**

在概览点击记录饮水后，饮水卡、最近活动、喝水页、统计页和成就页立即更新；在账本点击记一笔后，概览收支卡、账本列表、账本统计立即更新；切换深色模式后所有已挂载页面同步刷新。

## Task 7: 最终构建、排查表和视觉证据

**Files:**
- Read: all changed files
- Modify: `C:\Users\27363\Desktop\鸿蒙问题排查表.md` only after fresh evidence is collected
- Create: `artifacts/yuanqi-you-shu-final-audit.log`

- [ ] **Step 1: 运行完整 Hypium 和 HAP 构建。**

运行 `hvigorw.bat test`，预期 `Failure: 0, Error: 0`；运行 `hvigorw.bat assembleHap --mode module -p module=entry -p product=default`，预期 `BUILD SUCCESSFUL`。

- [ ] **Step 2: 运行静态排查脚本。**

运行 `& '.\tools\verify_harmony_review_checklist.ps1'`，并追加 SDK 22、无网络权限、统一刷新信号、四项导航和中性色审计；预期所有适用项通过。

- [ ] **Step 3: 在 API 22 设备验证视觉矩阵。**

分别验证浅色/深色的概览、喝水、账本、我的，以及提醒、饮品、植物、目标、资料、数据、协议、账本添加/编辑/统计页；确认顶部和底部内容不进入安全区，安全区颜色与页面一致，底部控件与导航区至少 28vp。

- [ ] **Step 4: 更新排查表结论。**

第 1、2、4、5、6、7、8、9 项附新证据；第 3 项明确代码提示已修复但代理提醒能力仍受 AppGallery Connect Profile 约束；第 10、11 项仅保留“不适用于 WaterReminder”的证据，不把其他应用功能引入本项目。

- [ ] **Step 5: 交付效果。**

提供新 HAP 路径、测试结果、静态审计结果、深浅色截图和未解决的外部提醒能力限制；不宣称未验证的真机能力已完成。

## 自审结果

- 规格覆盖：SDK 22/单机、安全区、统一刷新、深色完整令牌、四项导航、设置整合、协议、CSV/JSON 迁移、排查表回归均有对应任务。
- 占位符扫描：计划正文没有未定义任务、悬而未决的决策或空白步骤。
- 类型一致性：刷新接口统一为 `nextRefreshRevision(current: number | undefined)` 与 `publishDataRefresh(): void`；概览使用 `DrinkService` 与 `StatisticsService`；迁移接口统一为 `preview`/`commit`。
