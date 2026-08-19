# Apple 风格 UI 最终验收记录

日期：2026-08-17  
工程：`C:/Users/27363/Desktop/APP/WaterReminder`  
目标设备：HarmonyOS 6.0.2 (API 22) Pura 90 模拟器，1320 x 2856，竖屏

## 结论

本轮 Apple 风格重构已通过代码契约、对比度、设备测试、发布构建及浅色/深色视觉复核。四个主页面、数据管理页和重置确认弹窗均未发现关键文字截断、控件重叠、系统栏遮挡、底部导航遮挡或主题切换异常。

## 自动验证

- Apple UI contract：通过。
- Contrast contract：通过。
- DataManage 顶部对齐：通过，Scroll top 与 content top 均为 318px。
- 全量数据重置 contract：通过。
- 13 个滚动页面顶部对齐：通过。
- UI repair contract：通过。
- API 22 设备 Hypium：48/48 通过，Failure 0，Error 0。
- release ArkTS type check：通过。
- release signed HAP：构建成功，大小 1,739,151 字节。
- SHA-256：`D7D1F0640D8DB46E2D5A0ADBBBA0F95F60CBB926A312799E8BC178DA63495BC0`。

发布包：`entry/build/default/outputs/default/entry-default-signed.hap`

## 视觉证据

证据目录：`device-evidence/`

- `apple-ui-2026-08-17-light-{overview,water,ledger,settings}.png`
- `apple-ui-2026-08-17-dark-{overview,water,ledger,settings}.png`
- `apple-ui-2026-08-17-{light,dark}-data-manage.png`
- `apple-ui-2026-08-17-{light,dark}-reset-dialog.png`
- `apple-ui-2026-08-17-light-settings-bottom.png`

对应 `.json` 文件为同屏 ArkUI 布局树。重置弹窗仅打开并取消，未执行数据删除。

## 仍需真机补测

当前环境未提供平板、折叠屏、横屏及分屏/悬浮窗条件，因此这些形态标记为 unverified。发布前还应在目标真机抽查系统字体放大、触摸响应和长时间动画流畅度。

## 可复用规范

全局 Skill：`C:/Users/27363/.codex/skills/harmonyos-apple-ui/SKILL.md`
