# 元气有数

HarmonyOS 原生健康管理应用：科学饮水记录与个人记账合二为一，个性化饮水目标、饮水打卡与成就养成，加上多分类账单、月度预算与统计图表；数据全部保存在设备本地，不登录、不联网、不上传。

> 产品与交互设计见 [design.md](design.md)，HarmonyOS 上架自检与界面验收记录见 [docs/](docs/)。

## 技术栈

- HarmonyOS API 22（系统 6.0.2），ArkTS + ArkUI 声明式范式，Stage 模型（UIAbility）
- 设备类型：phone、tablet；安全区与底部控件留白统一走 `SafeAreaRules`，深浅色与主题色由 `Theme` token 集中管理
- 本地持久化：`@kit.ArkData` Preferences 以 JSON 字符串保存饮水记录、用户资料、应用设置、饮品、成就与植物；账本模块使用 relationalStore 关系型数据库（账单、分类、预算、连续达标状态表）
- 系统能力：`@kit.CoreFileKit`（备份导入导出与文件选择器）、`@kit.SensorServiceKit`（记录饮水时的振动反馈）、`@kit.AbilityKit`
- 无第三方运行时依赖，仅本地 OHPM 依赖（测试用 `@ohos/hypium` 1.0.28）
- 单元测试：`entry/src/ohosTest/` 下饮水规则与账本规则两组 Hypium 用例
- 构建工具：Hvigor 6.24.3；`tools/` 存放界面契约、对比度、图标资源与清单自检脚本

## 功能特性

**概览**

- 底部四个主标签：概览、喝水、账本、我的
- 概览页汇总今日饮水完成率与连续达标天数、本月收入支出与结余、快捷入口（记录饮水、记一笔）与最近活动摘要

**饮水记录**

- 快捷记录：150 / 250 / 300 / 500 ml 四个预设杯量单击即记，长按可选饮品
- 自定义输入任意毫升数并选择饮品；支持自定义饮品与杯量
- 10 种内置饮品：白水、茶、咖啡、牛奶、果汁、汤、运动饮料、气泡水、碳酸饮料、椰子水，各带水合系数与咖啡因含量
- 记录支持编辑、删除，误触后 3 秒内可撤销
- 首页水波纹进度实时展示当日完成率与剩余目标量

**饮水目标**

- 按体重与活动量自动计算每日目标，叠加特殊状态（孕期 +300 ml、哺乳期 +500 ml、生病 +200 ml）与气候因素（炎热 +300 ml、干燥 +200 ml）
- 结果取 50 ml 整数并限制在 1500 ~ 4500 ml；目标设置页展示「基础量 = 体重 × 33」的计算过程，支持手动覆盖
- 首次启动引导页采集昵称、体重与生活信息后给出初始目标

**数据统计**

- 本周柱状图（含目标线）、本月与全年热力日历
- 达标天数与日均摄入汇总
- 时段分析：上午 / 下午 / 晚上摄入占比
- 饮品构成：各饮品毫升数明细

**成就与植物**

- 14 项成就徽章：连续 7 / 30 / 100 / 365 天、累计 10 / 100 / 500 / 1000 升、早起之星、品味多样、八杯水达人、超额完成等
- 等级体系：水滴 → 溪流 → 河流 → 湖泊 → 海洋，按累计饮水量进阶
- 植物花园：6 种植物（向日葵、薰衣草、仙人掌、多肉、薄荷、樱花树），每次饮水即浇水，按阶段生长，满级后可存入花园再培养新植物

**个人账本**

- 记一笔：收入与支出，12 类默认支出（餐饮、交通、购物、居住、娱乐、医疗、教育、通讯、服饰、运动、社交、其他）与 6 类默认收入（工资、奖金、兼职、投资、红包、其他）
- 分类管理：新增自定义分类，32 种图标与 16 色可选
- 月预算：设置 / 修改每月预算，环形进度展示已用与剩余额度，并保留历史预算记录
- 账本统计：月度趋势折线、分类排行与占比
- 账单列表：按月分组、金额与备注展示、编辑与删除

**设置与数据**

- 个人资料：头像、昵称、体重、运动量、特殊状态、气候环境
- 6 套主题色与深色模式（跟随系统 / 浅色 / 深色），系统栏外观随页面与主题同步
- 关于与协议：应用版本信息与用户协议页面
- 备份与数据管理：全部数据导出为单个 JSON 文件、从备份文件恢复、重置数据（含二次确认）

## 截图

![应用图标](docs/assets/water-reminder-app-icon.png)

> 当前仓库未包含设备运行截图，验收阶段的界面契约、对比度与布局校验记录见 [docs/](docs/)（如 `docs/apple-ui-verification-2026-08-17.md`、`docs/harmony-review-final.md`）。

## 目录结构

```text
AppScope/                     应用级配置与分层图标资源
entry/src/main/
  ets/entryability/           UIAbility 入口（初始化账本数据库、主题与安全区）
  ets/pages/                  MainPage（四标签）、概览、饮水、统计、成就、设置、引导、
                              记录详情、饮品管理、目标设置、个人资料、植物花园、数据管理、协议
  ets/ledger/                 记账模块：pages / components / services / models / common
  ets/components/             水波纹进度、快捷添加、图表、卡片、弹窗等共享组件
  ets/services/               饮水、目标、统计、成就、植物、备份、偏好设置与系统栏服务
  ets/repositories/           饮水、饮品、成就、植物的本地持久化
  ets/models/                 记录、饮品、资料、成就、植物数据模型
  ets/common/                 主题 token、规则计算、日期工具、常量与演示数据
  resources/                  字符串、颜色、图标、路由配置
  module.json5                模块与权限声明
entry/src/ohosTest/           Hypium 单元测试
docs/                         设计、上架自检与界面校验记录
tools/                        界面契约与资源校验脚本
design.md                     产品与技术设计报告
build-profile.json5           工程构建配置
oh-package.json5              工程依赖
```

## 构建与运行

1. 安装 DevEco Studio（需支持 API 22 的 SDK 6.0.2），并在 SDK Manager 中安装 HarmonyOS 6.0.2(22) SDK
2. 用 DevEco Studio 打开仓库根目录，等待 SDK 与依赖同步完成
3. 在 DevEco Studio 中为本机配置自动签名（File → Project Structure → Signing Configs），或把自己的签名材料写入 `build-profile.json5` 的 `signingConfigs`
4. 选择 `entry` 模块运行；或构建并运行测试用例：

```powershell
# 主 HAP
hvigorw --mode module -p module=entry@default -p product=default assembleHap

# 测试 HAP（ohosTest）
hvigorw --mode module -p module=entry@ohosTest -p product=default assembleHap
```

## 隐私说明

- 权限：`entry/src/main/module.json5` 仅申请 `ohos.permission.VIBRATE`，用于记录饮水时的触感反馈
- 不申请网络相关权限，应用不含联网、上传与埋点逻辑
- 饮水记录、身体参数、植物与成就、账单与预算数据均写入设备本地 Preferences 与关系型数据库
- 备份为本地 JSON 文件导出，由用户自行保管，应用不上传该文件
- 无需注册与登录，不采集设备标识、位置与联系人信息

## 许可

本项目以 Apache License 2.0 声明许可，详见 `oh-package.json5` 的 `license` 字段（仓库当前未包含独立的 LICENSE 文件）。