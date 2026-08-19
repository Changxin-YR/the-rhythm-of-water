# 元气有数 — 开发报告

## 一、产品定位

**产品名称**：元气有数

**一句话定位**：一款简约高级、功能全面的纯鸿蒙健康管理应用，融合科学饮水管理与个人记账，帮助用户管理每日水分摄入与日常收支。

**目标用户**：关注健康的年轻白领、健身爱好者、孕产期女性、办公久坐人群。

**核心价值**：
- 科学计算个性化饮水目标
- 个人收支记账与分类管理
- 直观有趣的数据可视化
- 简约高级的交互体验

---

## 二、功能模块设计

### 2.1 核心饮水追踪

| 功能 | 说明 |
|------|------|
| 一键快速记录 | 首页预设杯量按钮（150ml/250ml/300ml/500ml），单击即可记录 |
| 自定义输入 | 支持手动输入任意毫升数 |
| 多饮品类型 | 预置白水、茶、咖啡、牛奶、果汁、汤、运动饮料、气泡水等，各类饮品有不同的水合系数 |
| 自定义饮品 | 用户可添加自定义饮品名称、图标、水合百分比 |
| 自定义杯具 | 可保存常用杯具容量（如「我的保温杯 450ml」） |
| 记录编辑/删除 | 支持修改或删除已记录的饮水条目 |
| 撤销操作 | 误触一键记录后可立即撤销 |
| 实时进度展示 | 首页水波纹动画显示当日完成百分比 |
| 剩余量提示 | 显示距离目标还需饮用的量 |

### 2.2 智能目标系统

| 功能 | 说明 |
|------|------|
| 个性化目标计算 | 基于体重、性别、年龄、运动量自动计算推荐饮水量 |
| 运动强度调节 | 久坐/轻度活动/中度活动/高强度/运动员 五级 |
| 气候调整 | 高温/干燥/潮湿环境下自动建议增加饮水量 |
| 特殊状态 | 孕期/哺乳期/生病状态下的额外补水建议 |
| 手动覆盖 | 用户可随时自定义每日目标（不受公式限制） |
| 目标自动更新 | 体重等参数变化后，系统提示重新计算目标 |

### 2.4 数据统计与分析

| 功能 | 说明 |
|------|------|
| 今日摘要 | 总量、杯数、目标完成率、饮品构成 |
| 周度报告 | 柱状图展示每日摄入量 + 均值线 + 达标天数 |
| 月度报告 | 热力日历（颜色深浅表示完成度）+ 趋势折线 |
| 年度总结 | 全年喝水总量、最佳连续天数、月均摄入趋势 |
| 时段分析 | 分析一天中饮水高峰和低谷时段 |
| 饮品构成 | 饼图展示各类饮品占比 |
| 数据导出 | 支持 JSON 格式备份和恢复 |

### 2.5 成就与激励系统

| 功能 | 说明 |
|------|------|
| 连续打卡天数 | 显示当前连续达标天数（Streak） |
| 最长连续记录 | 历史最佳连续天数 |
| 成就徽章 | 里程碑解锁（首次达标/7天连续/30天连续/100天连续/累计100L等） |
| 等级系统 | 基于累计饮水量升级（水滴→溪流→河流→湖泊→海洋） |
| 每日挑战 | 如「早8点前喝第一杯」「今日8杯水」等随机挑战 |
| 植物养成 | 每次喝水浇灌虚拟植物，植物随饮水量成长 |

### 2.6 个性化设置

| 功能 | 说明 |
|------|------|
| 个人资料 | 昵称、体重、身高、年龄、性别、运动量 |
| 单位切换 | 毫升(ml)/升(L)/盎司(oz) |
| 深色模式 | 跟随系统或手动切换 |
| 主题色选择 | 提供 6 种主题色方案（默认水蓝色） |
| 每日重置时间 | 默认00:00，可调整为自定义时间 |
| 语言 | 中文（简体） |
| 数据备份/恢复 | 本地 JSON 备份导入导出 |

---

## 三、页面架构

### 3.1 页面列表与路由

```
主框架 (MainPage) — Tabs 底部导航
├── 首页 (HomePage)             — 核心饮水追踪
├── 统计 (StatsPage)            — 数据分析
├── 成就 (AchievementPage)      — 成就与激励
└── 设置 (SettingsPage)         — 个人配置

独立页面（从以上页面跳转）
├── 引导页 (OnboardingPage)     — 首次使用信息采集
├── 记录详情 (RecordDetailPage) — 查看/编辑单条记录
├── 饮品管理 (BeveragePage)     — 管理饮品列表
├── 杯具管理 (CupPage)          — 管理常用杯具
├── 目标设置 (GoalSettingsPage)     — 目标计算与调整
├── 个人资料 (ProfilePage)          — 身体参数编辑
├── 植物花园 (PlantGardenPage)      — 虚拟植物养成
└── 数据管理 (DataManagePage)       — 备份/恢复/重置
```

### 3.2 页面信息架构

#### 首页 (HomePage)
```
┌──────────────────────────────┐
│        今日 · 周三           │
│                              │
│     ╭─────────────────╮      │
│     │                 │      │
│     │   水波纹动画     │      │
│     │   1200 / 2000ml │      │
│     │     60%         │      │
│     ╰─────────────────╯      │
│                              │
│   还需喝 800ml 即可达标      │
│                              │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐│
│  │150 │ │250 │ │300 │ │500 ││
│  │ ml │ │ ml │ │ ml │ │ ml ││
│  └────┘ └────┘ └────┘ └────┘│
│                              │
│  [  + 自定义输入  ]          │
│                              │
│  ── 今日记录 ──────────────  │
│  ☕ 咖啡 250ml    08:30      │
│  💧 白水 300ml    10:00      │
│  🍵 绿茶 200ml    14:15      │
│                              │
├──────────────────────────────┤
│  🏠首页  📊统计  🏆成就  ⚙设置│
└──────────────────────────────┘
```

#### 统计页 (StatsPage)
```
┌──────────────────────────────┐
│  [本周] [本月] [本年]        │
│                              │
│  ┌────────────────────────┐  │
│  │    周度柱状图           │  │
│  │    ▄▄█▄▆▄_            │  │
│  │    均值线 ──────        │  │
│  └────────────────────────┘  │
│                              │
│  达标天数: 5/7   均值: 1850ml│
│                              │
│  ── 时段分析 ──              │
│  上午: ████████ 45%         │
│  下午: █████ 30%            │
│  晚上: ████ 25%             │
│                              │
│  ── 饮品构成 ──              │
│  白水 60% | 茶 25% | 其他15%│
└──────────────────────────────┘
```

---

## 四、技术架构

### 4.1 技术栈

| 项目 | 选型 |
|------|------|
| 平台 | HarmonyOS 6.0.2 |
| SDK | API 22 |
| 语言 | ArkTS |
| UI框架 | ArkUI 声明式 |
| 应用模型 | Stage 模型 |
| 数据存储 | Preferences（设置）+ RDB/文件存储（记录数据） |
| 振动反馈 | vibrator 模块（记录操作触感） |
| 桌面卡片 | Form Kit（2×2 / 2×4 快捷记录卡片） |
| 构建工具 | Hvigor |

### 4.2 工程目录结构

```
entry/src/main/ets/
├── entryability/
│   └── EntryAbility.ets          -- 应用入口 Ability
├── pages/
│   ├── MainPage.ets              -- 主框架（底部Tab）
│   ├── HomePage.ets              -- 首页
│   ├── StatsPage.ets             -- 统计页
│   ├── AchievementPage.ets       -- 成就页
│   ├── SettingsPage.ets          -- 设置页
│   ├── OnboardingPage.ets        -- 引导页
│   ├── RecordDetailPage.ets      -- 记录详情
│   ├── BeveragePage.ets          -- 饮品管理
│   ├── CupPage.ets               -- 杯具管理
│   ├── GoalSettingsPage.ets      -- 目标设置
│   ├── ProfilePage.ets           -- 个人资料
│   ├── PlantGardenPage.ets       -- 植物花园
│   └── DataManagePage.ets        -- 数据管理
├── components/
│   ├── WaterWaveProgress.ets     -- 水波纹进度组件
│   ├── QuickAddButton.ets        -- 快捷添加按钮
│   ├── DrinkRecordItem.ets       -- 饮水记录条目
│   ├── StatsBarChart.ets         -- 柱状图组件
│   ├── HeatmapCalendar.ets       -- 热力日历组件
│   ├── AchievementCard.ets       -- 成就卡片组件
│   ├── PlantView.ets             -- 植物展示组件
│   ├── BeverageSelector.ets      -- 饮品选择器
│   ├── AmountInputDialog.ets     -- 自定义输入弹窗
│   └── TimeRangePicker.ets       -- 时间范围选择器
├── services/
│   ├── DrinkService.ets          -- 饮水记录服务
│   ├── GoalService.ets           -- 目标计算服务
│   ├── AchievementService.ets    -- 成就计算服务
│   ├── StatsService.ets          -- 统计分析服务
│   ├── PlantService.ets          -- 植物养成服务
│   ├── BackupService.ets         -- 数据备份恢复服务
│   └── PreferencesService.ets    -- 偏好设置服务
├── repositories/
│   ├── DrinkRepository.ets       -- 饮水记录持久化
│   ├── BeverageRepository.ets    -- 饮品配置持久化
│   ├── AchievementRepository.ets -- 成就数据持久化
│   └── PlantRepository.ets       -- 植物数据持久化
├── models/
│   ├── DrinkRecord.ets           -- 饮水记录模型
│   ├── Beverage.ets              -- 饮品模型
│   ├── Cup.ets                   -- 杯具模型
│   ├── DailySummary.ets          -- 每日摘要模型
│   ├── Achievement.ets           -- 成就模型
│   ├── Plant.ets                 -- 植物模型
│   ├── UserProfile.ets           -- 用户资料模型
├── common/
│   ├── Constants.ets             -- 全局常量
│   ├── Theme.ets                 -- 主题色/字体/间距 token
│   ├── Routes.ets                -- 路由常量
│   ├── DateUtils.ets             -- 日期工具
│   ├── IdGenerator.ets           -- ID 生成工具
│   └── GoalCalculator.ets        -- 目标计算公式
└── resources/
    ├── base/
    │   ├── element/
    │   │   ├── string.json       -- 字符串资源
    │   │   └── color.json        -- 颜色资源
    │   ├── media/                 -- 图标、植物图片等
    │   └── profile/
    │       └── main_pages.json   -- 页面路由注册
```

### 4.3 数据模型

```typescript
// 饮水记录
export interface DrinkRecord {
  id: string
  beverageId: string      // 饮品ID
  beverageName: string    // 饮品名称
  amountMl: number        // 实际毫升数
  hydrationMl: number     // 有效水合量 = amountMl × hydrationRate
  happenedAt: number      // 记录时间戳
  createdAt: number
  updatedAt: number
}

// 饮品类型
export interface Beverage {
  id: string
  name: string
  icon: string            // 图标资源名
  hydrationRate: number   // 水合系数 (0.0 ~ 1.0)
  caffeinePerMl: number   // 咖啡因含量
  isCustom: boolean       // 是否用户自定义
  isActive: boolean       // 是否启用
}

// 杯具
export interface Cup {
  id: string
  name: string
  capacityMl: number
  icon: string
  isDefault: boolean
}

// 用户资料
export interface UserProfile {
  nickname: string
  weightKg: number
  heightCm: number
  age: number
  gender: 'male' | 'female'
  activityLevel: 'sedentary' | 'light' | 'moderate' | 'active' | 'athlete'
  specialState: 'none' | 'pregnant' | 'breastfeeding' | 'sick'
  dailyGoalMl: number          // 当前每日目标
  isGoalAutoCalculated: boolean // 目标是否自动计算
}

// 每日摘要
export interface DailySummary {
  date: string              // YYYY-MM-DD
  totalMl: number           // 总饮入量
  hydrationMl: number       // 有效水合量
  goalMl: number            // 当日目标
  completionRate: number    // 完成率
  recordCount: number       // 记录条数
  beverageBreakdown: Record<string, number>  // 各饮品ID→毫升数
  streakDay: number         // 当前连续天数
}

// 成就
export interface Achievement {
  id: string
  title: string
  description: string
  icon: string
  condition: string        // 达成条件描述
  unlockedAt: number | null
  progress: number         // 0~100
}

// 虚拟植物
export interface Plant {
  id: string
  species: string          // 植物种类
  name: string             // 用户命名
  growthStage: number      // 成长阶段 0~5
  waterReceived: number    // 累计获得浇水量
  waterNeeded: number      // 进入下一阶段所需量
  createdAt: number
  isActive: boolean        // 当前培养中
}
```

### 4.4 目标计算公式

```
基础量 = 体重(kg) × 33 (ml)

活动量调节：
  久坐: ×1.0
  轻度活动: ×1.1
  中度活动: ×1.2
  高强度: ×1.3
  运动员: ×1.5

特殊状态：
  孕期: +300ml
  哺乳期: +500ml
  生病: +200ml

气候调节（手动选择）：
  炎热: +300ml
  干燥: +200ml
  正常: +0ml

最终目标 = 基础量 × 活动系数 + 特殊状态 + 气候调节
范围限制: 最低1500ml，最高4500ml
```

---

## 五、UI 设计规范

### 5.1 设计理念

**简约而高级**：以「留白 + 圆润 + 渐变」为核心，营造清爽宁静感。

### 5.2 视觉系统

| Token | 值 |
|-------|----|
| 主色 | #4FC3F7（清澈水蓝） |
| 主色深 | #0288D1 |
| 辅助色 | #81D4FA（浅水蓝） |
| 强调色 | #26C6DA（青绿） |
| 背景色 | #F8FBFF（极浅蓝白） |
| 卡片色 | #FFFFFF |
| 文字主色 | #1A2A3A |
| 文字次色 | #6B7B8B |
| 成功色 | #66BB6A |
| 警告色 | #FFA726 |
| 圆角 | 卡片 20px / 按钮 16px / 芯片 24px |
| 字体 | HarmonyOS Sans |
| 标题 | 24sp Bold |
| 正文 | 16sp Regular |
| 辅助文字 | 13sp Regular |
| 间距基准 | 8px 网格 |

### 5.3 深色模式

| Token | 深色值 |
|-------|--------|
| 背景色 | #0D1B2A |
| 卡片色 | #1B2838 |
| 文字主色 | #E8F0F8 |
| 文字次色 | #8899AA |

### 5.4 动效设计

- 水波纹进度：实时波浪动画，水位随饮水量上升
- 记录添加：涟漪扩散 + 轻微震感反馈
- 植物成长：缓慢生长动画
- 达标庆祝：彩纸飘落粒子效果
- 页面转场：共享元素过渡

---

## 六、交互设计

### 6.1 核心交互流程

**快速记录流程（2步完成）**：
1. 点击预设杯量按钮 → 自动记录（默认为白水）
2. 长按杯量按钮 → 弹出饮品选择器 → 选择饮品后记录

**自定义记录流程**：
1. 点击「+ 自定义」→ 弹出输入弹窗
2. 输入毫升数 + 选择饮品类型 → 确认

**撤销流程**：
记录后底部出现 3 秒 Snackbar「已记录 250ml 白水 [撤销]」

### 6.2 手势设计

- 首页下拉：刷新今日数据
- 记录列表左滑：删除
- 统计页左右滑动：切换日期范围

---

## 八、植物养成系统

### 8.1 机制设计

- 用户每次喝水 = 给当前植物浇水
- 累计浇水量达到阈值 → 植物进入下一阶段
- 成长阶段：种子 → 发芽 → 幼苗 → 生长 → 开花 → 结果
- 连续未达标 3 天 → 植物枯萎（不死亡，恢复后复苏）
- 植物满级后可存入花园，开始培养新植物

### 8.2 植物种类（初始版本）

- 向日葵、薰衣草、仙人掌、多肉、薄荷、樱花树
- 每个种类有独立的 6 阶段图片资源

---

## 九、开发计划

### Phase 1 — 核心功能（优先）
1. 工程搭建 + 路由配置
2. 数据模型 + 存储层
3. 首页（水波纹 + 快速记录 + 记录列表）
4. 引导页（资料采集 + 目标计算）
5. 基础设置页

### Phase 2 — 分析与激励
7. 统计页（周/月/年图表）
8. 成就系统
9. 连续打卡
10. 植物养成

### Phase 3 — 完善与优化
11. 深色模式适配
12. 动效打磨
13. 数据备份/恢复
14. 性能优化
15. 全面测试与修复

---

## 十、非功能性要求

| 维度 | 要求 |
|------|------|
| 启动时间 | 冷启动 < 2s |
| 内存占用 | 常驻 < 50MB |
| 存储空间 | 应用 < 30MB，数据随使用增长 |
| 兼容性 | HarmonyOS 6.0+ / SDK 22 |
| 设备 | 手机（优先）、平板（自适应） |
| 无障碍 | 触摸目标 ≥ 44px，支持大字体 |
| 安全 | 本地存储，无网络传输，无隐私泄露 |

---

## 十一、权限与系统能力声明

### module.json5 权限

```json
"requestPermissions": [
  {
    "name": "ohos.permission.VIBRATE"
  }
]
```

### 系统能力依赖

| 能力 | 用途 |
|------|------|
| @ohos.vibrator | 记录操作振动反馈 |
| @ohos.data.preferences | 设置/配置持久化 |
| @ohos.data.relationalStore | 饮水记录/成就/植物/账单数据持久化 |
| @ohos.file.fs | 数据导出导入（JSON文件） |

---

## 十二、桌面卡片（Form Widget）

### 卡片类型

| 尺寸 | 内容 |
|------|------|
| 2×2 小卡片 | 当日进度环 + 当前量/目标量 + 快捷「+250ml」按钮 |
| 2×4 中卡片 | 进度环 + 多个快捷杯量按钮 + 剩余量文字 |

### 交互
- 点击卡片主体 → 打开应用首页
- 点击快捷按钮 → 直接记录（无需打开应用），卡片即时刷新进度
- 进度满 100% 后显示达标状态

### 刷新策略
- 每次应用内记录后主动刷新卡片
- 每 30 分钟系统调度刷新一次（保持数据一致）

---

## 十三、风险与约束

| 风险 | 应对 |
|------|------|
| 水波纹动画性能 | 使用 Canvas 绘制，控制刷新频率 ≤ 30fps |
| 数据量增长 | 分页加载 + 按月归档 |
| 植物图片资源大 | 使用矢量风格 SVG 减小体积 |
| 深色模式遗漏 | 统一从 Theme token 取色，不硬编码 |

---

## 十四、验收标准

1. 所有页面正常渲染，无空白/崩溃
2. 饮水记录增删改查完整可用
3. 统计图表数据准确，与记录一致
4. 成就/植物逻辑正确触发
5. 深色模式全页面适配
6. 从引导→日常使用→数据回顾 完整链路通畅
7. 构建无错误，无新增弃用 API
8. 数据持久化：关闭应用后数据不丢失
