# WaterReminder 上架整改设计

## 目标

在不改动签名配置、不新增隐私协议的前提下，完成当前审查中剩余的可执行整改：HarmonyOS 分层应用图标、真正的沉浸式窗口布局、用户可取得的备份文件，以及 API 22 / HarmonyOS 6.0.2 目标验证。

## 范围

包含：

- 保留原有水滴、水杯、绿叶和蓝绿色品牌识别，重制规范分层图标。
- 开启窗口级沉浸式布局，同时保持内容避让系统安全区。
- 将备份从应用私有目录改为由用户选择保存位置。
- 保持 compatible/target SDK 为 `6.0.2(22)`，并在 API 22 / 6.0.2 设备上验证。

不包含：

- 修改签名文件路径、签名口令或证书配置。
- 增加用户协议、隐私政策或首次同意流程。
- 与上述整改无关的页面重构或视觉改版。

## 图标设计

采用已确认的“忠实分层重制”方案：主体仍由水滴、水杯、飞溅水珠和绿叶组成，保持现有蓝绿色调与立体高光风格。资源不保留预制圆角、白色边框、顶部残线或额外内间距。

工程资源使用 HarmonyOS `layered-image`：

- `app_icon_foreground.png`：`1024 x 1024` 透明 PNG，只包含主体与必要阴影。
- `app_icon_background.png`：`1024 x 1024` 不透明 PNG，提供完整方形浅蓝背景。
- `app_icon_layered.json`：引用前景和背景资源。
- AppScope 和 entry 均放置同名三项资源，避免资源合并优先级造成不一致。
- `AppScope/app.json5` 与 UIAbility 的 `icon` 改用 `$media:app_icon_layered`。
- `startWindowIcon` 使用前景资源，启动背景继续使用现有主题色。
- `release-assets/WaterReminder-AppGallery-icon-1024x1024.png` 更新为无预制圆角的完整方形合成图，供上架资料使用。

## 沉浸式布局

`resolveSystemBarAppearance()` 返回 `useImmersiveLayout: true`，由现有 `SystemBarService` 开启窗口全屏布局。`SystemSafeAreaBackground` 继续扩展到顶部和底部系统区域，业务内容维持现有安全区布局，不把标题、按钮或底栏放到系统图标下面。

深色和浅色主题继续分别设置系统栏内容颜色，避免沉浸后状态栏图标失去对比度。

## 备份导出

数据管理页在生成 JSON 后打开 `DocumentViewPicker` 保存界面，并预填 `aquaflow_backup_<timestamp>.json`。用户选择位置后，应用直接把备份内容写入返回的 URI。

`BackupService` 不再把导出文件固定写入 `context.filesDir`，而是提供写入目标 URI 的单一职责方法。写入使用创建/写入/截断模式并始终关闭文件描述符，避免覆盖旧文件时残留尾部数据。

用户取消保存时不显示失败；保存成功后只提示“备份已保存”，不显示应用私有路径。恢复流程继续使用现有 `.json` 文件选择器和完整载荷校验。

## SDK 口径

项目继续以 `compatibleSdkVersion` 和 `targetSdkVersion` 的 `6.0.2(22)` 作为运行兼容目标。当前 DevEco 编译工具链为 `6.1.1.125`，它只影响编译器版本，不把最终 HAP 的 target/min API 提升到 24，因此不强制降级或安装另一套编译器。

验收以最终 HAP 的 `targetAPIVersion/minAPIVersion = 60002022`、API 22 设备系统参数 `6.0.2`，以及该设备上的测试结果为准。

## 测试与验收

- 先把沉浸式规则测试改为期望 `true`，确认旧实现产生预期失败，再修改生产代码。
- 为备份文件名和目标 URI 写入边界补充可测试逻辑；取消保存和写入失败由页面反馈覆盖。
- 运行完整 Hypium 测试套件，要求零失败、零错误。
- 执行 release 构建并验证签名 HAP 能被解析。
- 检查分层前景/背景均为 `1024 x 1024`，前景包含透明通道，背景完全不透明，描述文件引用正确。
- 在 API 22 / HarmonyOS 6.0.2 模拟器安装 release HAP，检查桌面图标、启动页、浅色/深色沉浸布局。
- 手动完成一次备份保存与恢复闭环，确认文件能在用户选择的位置重新选取。

