# 元气有数单一底部导航实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 移除账本内部顶部 TabBar，在保留原账本功能的前提下，把账本首页、交易记录、统计、分类和预算整合成单一底部导航下的清晰页面。

**Architecture:** `MainPage` 继续作为唯一一级导航容器；`LedgerHomePage` 只负责账本首页和“交易记录”子页面切换，不再创建 `Tabs`；统计、分类和预算通过现有独立页面路由进入，账本设置/导出/清空归入统一 `SettingsPage`。账本颜色全部通过 `ledgerColor()` 语义牌解析，与主应用蓝色主题和深色模式同步。

**Tech Stack:** HarmonyOS ArkTS、SDK/target 22、现有 BillService/CategoryService/StatisticsService/DataChangeNotifier、hvigor、Hypium。

---

### Task 1: 将账本改成单页内容 + 工具入口

**Files:**
- Modify: `entry/src/main/ets/ledger/pages/LedgerHomePage.ets`
- Test: `entry/src/ohosTest/ets/test/**`（沿用现有账本导航和账单 CRUD 测试）

- [ ] **Step 1: 删除内部 Tab 状态与渲染器**

删除 `currentTabIndex`、`tabsController`、`getTabBarHeight()`、`TabBarBuilder()`，并把 `build()` 的 `Tabs` 替换为单一内容分支：

```ts
@State ledgerView: number = 0; // 0 首页，1 交易记录

build() {
  Stack() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(ledgerColor('ledger_canvas'));

    Column() {
      if (this.ledgerView === 0) {
        this.HomeTab();
      } else {
        this.BillsTab();
      }
    }
    .width('100%')
    .height('100%')
    .constraintSize({ maxWidth: ResponsiveUtils.getContentMaxWidth(this.currentBreakpoint) });
  }
  .width('100%')
  .height('100%')
  .onAreaChange((oldValue: Area, newValue: Area) => {
    this.currentBreakpoint = ResponsiveUtils.fromAreaWidth(newValue.width, (value: number) => this.getUIContext().px2vp(value));
    this.ensurePageDataLoaded();
  });
}
```

- [ ] **Step 2: 增加账本工具卡片**

在 `HomeTab()` 的月度摘要和今日交易区之间调用 `this.LedgerTools()`，并新增四张卡片。卡片动作必须使用现有能力：交易记录设置 `ledgerView = 1`，统计/分类/预算分别 `router.pushUrl()` 到既有页面。

```ts
@Builder
LedgerTools() {
  Column({ space: 10 }) {
    Row({ space: 10 }) {
      this.LedgerToolCard('bills', $r('app.string.ledger_tab_bills'), $r('app.string.ledger_bills_subtitle'), () => {
        this.ledgerView = 1;
      });
      this.LedgerToolCard('statistics', $r('app.string.ledger_tab_statistics'), $r('app.string.ledger_stats_subtitle'), () => {
        router.pushUrl({ url: 'pages/ledger/LedgerStatisticsPage' });
      });
    }
    .width('100%');
    Row({ space: 10 }) {
      this.LedgerToolCard('settings', $r('app.string.ledger_category_manage'), $r('app.string.ledger_category_ranking'), () => {
        router.pushUrl({ url: 'pages/ledger/LedgerCategoryManagePage' });
      });
      this.LedgerToolCard('calendar', $r('app.string.ledger_budget_manage'), $r('app.string.ledger_budget_set_tip'), () => {
        router.pushUrl({ url: 'pages/ledger/LedgerBudgetPage' });
      });
    }
    .width('100%');
  }
  .width('100%')
  .margin({ top: 18 });
}

@Builder
LedgerToolCard(icon: LedgerIconName, title: Resource, subtitle: Resource, action: () => void) {
  Column() {
    LedgerIcon({ name: icon, active: true }).width(26).height(26);
    Text(title).fontSize(Constants.FONT_BODY).fontWeight(FontWeight.Bold).fontColor(ledgerColor('ledger_ink')).margin({ top: 10 });
    Text(subtitle).fontSize(Constants.FONT_SMALL).fontColor(ledgerColor('ledger_muted')).margin({ top: 4 }).maxLines(1);
  }
  .layoutWeight(1)
  .padding({ left: 12, right: 12, top: 14, bottom: 14 })
  .backgroundColor(ledgerColor('ledger_surface'))
  .borderRadius(Constants.RADIUS_MD)
  .shadow({ radius: 8, color: ledgerColor('ledger_card_shadow'), offsetX: 0, offsetY: 3 })
  .onClick(action);
}
```

- [ ] **Step 3: 将“查看全部”与返回动作改为子页面状态**

`HomeTab()` 的“查看全部”只设置 `this.ledgerView = 1`，不再调用 `tabsController.changeIndex()`。`BillsTab()` 标题行增加返回按钮，点击设置 `this.ledgerView = 0`；不增加任何顶部 TabBar。

- [ ] **Step 4: 编译验证本任务**

Run: `hvigorw.bat assembleHap --mode module -p module=entry@ohosTest -p product=default --no-daemon`

Expected: `TYPE CHECK SUCCESSFUL` and `BUILD SUCCESSFUL`，且输出中不再出现 `Tabs` 相关类型错误。

### Task 2: 统一账本颜色语义，保持深色模式真实适配

**Files:**
- Modify: `entry/src/main/ets/ledger/common/LedgerTheme.ets`
- Modify: `entry/src/main/resources/base/element/color.json`（仅在已有语义色缺失时补齐）
- Modify: `entry/src/main/resources/dark/element/color.json`（确保新增/使用的语义色有深色覆盖）

- [ ] **Step 1: 对齐主应用蓝色视觉**

把 `ledger_primary_color`、`ledger_primary_light`、`ledger_primary_surface`、`ledger_accent` 的浅色值对齐主应用蓝色；深色使用高亮蓝和深蓝表面；收入使用绿色，支出使用暖橙/红色，文字、卡片和分割线继续通过 `ledgerColor()` 解析。

```ts
case 'ledger_primary_color': return dark ? '#8EA7FF' : '#4668F3'
case 'ledger_primary_light': return dark ? '#22335C' : '#EAF0FF'
case 'ledger_primary_surface': return dark ? '#2D4280' : '#D9E5FF'
case 'ledger_accent': return dark ? '#78AAFF' : '#6A86FF'
case 'ledger_income_green': return dark ? '#68D3B0' : '#0E9F83'
case 'ledger_expense_red': return dark ? '#FF9D78' : '#E46A3D'
```

- [ ] **Step 2: 保留对比度与按钮可读性**

确认渐变按钮仍使用 `ledger_card_text_primary`（白色），普通卡片文字使用 `ledger_ink`/`ledger_muted`；不得在业务页面新增 `Color.White`、纯黑背景或低于 10fp 的字体。

- [ ] **Step 3: 运行静态主题审计**

Run: `powershell -ExecutionPolicy Bypass -File .\tools\verify_harmony_review_checklist.ps1`

Expected: `HarmonyOS review audit passed (15 checks).`

### Task 3: 构建、安装、真机交互和回归验证

**Files:**
- Modify: `docs/harmony-review-final.md`（追加本次账本导航重构验证结果）
- Output: `entry/build/default/outputs/default/entry-default-signed.hap`

- [ ] **Step 1: 运行全部 Hypium 测试**

Run:

```powershell
hvigorw.bat assembleHap --mode module -p module=entry@ohosTest -p product=default --no-daemon
hdc -t 127.0.0.1:5555 install -r .\entry\build\default\outputs\ohosTest\entry-ohosTest-signed.hap
hdc -t 127.0.0.1:5555 shell aa test -b com.aquaflow.waterreminder -m entry_test -s unittest OpenHarmonyTestRunner -s timeout 60000 -w 90000
```

Expected: `Failure 0`, `Error 0`，且账本新增、编辑、删除和统计相关测试全部通过。

- [ ] **Step 2: 构建 debug/release HAP**

Run:

```powershell
hvigorw.bat assembleHap --mode module -p module=entry -p product=default -p buildMode=debug --no-daemon
hvigorw.bat assembleHap --mode module -p module=entry -p product=default -p buildMode=release --no-daemon
```

Expected: 两次均 `BUILD SUCCESSFUL`，release HAP 生成在 `entry/build/default/outputs/default/entry-default-signed.hap`。

- [ ] **Step 3: 真机验收主导航和账本入口**

安装 release HAP 后依次验证：

1. 底部只有“概览/喝水/账本/我的”四项；
2. 进入“账本”后不存在“首页/账单/统计/设置”顶部 TabBar；
3. 四个账本工具入口分别打开原有功能；
4. “查看全部”和返回按钮能在账本首页/交易记录间切换；
5. 浅色/深色切换时账本卡片、工具卡、交易列表、底部导航和系统安全区同步变色；
6. 新增账单后返回总览，饮水与账本摘要都能在同一刷新周期内更新。

- [ ] **Step 4: 更新报告并复核排查表**

在 `docs/harmony-review-final.md` 记录：内部 TabBar 已移除、功能入口映射、15/15 静态审计、Hypium 通过数、debug/release 构建结果和真机截图路径。

### Self-review checklist

- Spec coverage: Task 1 covers sole bottom navigation and ledger function mapping; Task 2 covers visual/deep-mode requirements; Task 3 covers SDK 22-compatible build, refresh, safe-area and checklist verification.
- Placeholder scan: no TBD/TODO or unspecified implementation steps remain; all commands and touched files are explicit.
- Type consistency: `ledgerView` is a numeric state shared by `build()`, `HomeTab()` and `BillsTab()`; tool actions use existing `LedgerIconName` values and existing route names.
