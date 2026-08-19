# 元气有数界面修复与用户协议 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复当前已复现的路由、可读性、安全区和协议内容问题，并验证相关鸿蒙审核项。

**Architecture:** 保留现有 ArkTS 页面和主题结构。路由问题只补齐页面清单；账本可读性复用现有语义色；协议页在原页面内改写，不新增页面或依赖。

**Tech Stack:** ArkTS、ArkUI、Hypium、PowerShell 静态契约检查。

---

### Task 1: 建立路由和可读性回归检查

**Files:**
- Create: `tools/verify_ui_repair_contract.ps1`
- Test: `tools/verify_ui_repair_contract.ps1`

- [ ] **Step 1: 写入失败检查**

```powershell
Assert-Contains 'entry/src/main/resources/base/profile/main_pages.json' 'pages/StatsPage'
Assert-Contains 'entry/src/main/ets/ledger/pages/LedgerBudgetPage.ets' '.fontColor(ledgerColor(''ledger_ink''))'
```

- [ ] **Step 2: 运行检查并确认当前失败**

Run: `powershell -ExecutionPolicy Bypass -File tools/verify_ui_repair_contract.ps1`

Expected: 页面清单和输入框颜色断言失败。

- [ ] **Step 3: 完成最小修复**

```json
"pages/StatsPage",
"pages/AchievementPage",
"pages/SettingsPage"
```

```ets
.fontColor(ledgerColor('ledger_ink'))
.placeholderColor(ledgerColor('ledger_text_secondary'))
```

- [ ] **Step 4: 重新运行检查**

Run: `powershell -ExecutionPolicy Bypass -File tools/verify_ui_repair_contract.ps1`

Expected: `PASS`。

### Task 2: 重写用户协议并修复顶部安全区

**Files:**
- Modify: `entry/src/main/ets/pages/ProtocolPage.ets`
- Test: `tools/verify_ui_repair_contract.ps1`

- [ ] **Step 1: 增加协议页面失败断言**

```powershell
Assert-Contains 'entry/src/main/ets/pages/ProtocolPage.ets' "Text('用户协议')"
Assert-Contains 'entry/src/main/ets/pages/ProtocolPage.ets' "@StorageProp('safeAreaTop')"
```

- [ ] **Step 2: 运行检查并确认当前失败**

Run: `powershell -ExecutionPolicy Bypass -File tools/verify_ui_repair_contract.ps1`

Expected: 旧标题和缺少顶部安全区断言失败。

- [ ] **Step 3: 重写页面内容**

```ets
Text('用户协议')
.padding({ top: this.safeAreaTop + 12 })
```

协议正文覆盖服务、本地数据、提醒、账本、规范、免责与变更，不保留历史项目名称或旧 CSV 导入描述。

- [ ] **Step 4: 重新运行检查**

Run: `powershell -ExecutionPolicy Bypass -File tools/verify_ui_repair_contract.ps1`

Expected: `PASS`。

### Task 3: 放大预算圆环中心文字并完成验收

**Files:**
- Modify: `entry/src/main/ets/ledger/pages/LedgerBudgetPage.ets`
- Modify: `tools/verify_ui_repair_contract.ps1`

- [ ] **Step 1: 增加失败断言**

```powershell
Assert-Contains 'entry/src/main/ets/ledger/pages/LedgerBudgetPage.ets' "ctx.font = 'bold 42px sans-serif'"
```

- [ ] **Step 2: 运行检查并确认当前失败**

Run: `powershell -ExecutionPolicy Bypass -File tools/verify_ui_repair_contract.ps1`

Expected: Canvas 字号断言失败。

- [ ] **Step 3: 仅提高 Canvas 文本字号**

```ets
ctx.font = 'bold 42px sans-serif';
ctx.font = '18px sans-serif';
```

- [ ] **Step 4: 运行完整验证**

Run: `powershell -ExecutionPolicy Bypass -File tools/verify_ui_repair_contract.ps1; powershell -ExecutionPolicy Bypass -File tools/verify_harmony_review_checklist.ps1`

Expected: 两项检查均通过。
