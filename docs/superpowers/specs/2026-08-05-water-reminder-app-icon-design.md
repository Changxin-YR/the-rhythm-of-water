# WaterReminder 应用图标替换设计

## 1. 目标

将用户提供的水杯图标用于 WaterReminder 的 HarmonyOS 应用图标，清除原图四角的黑色背景，保留主体与安全留白，并确保桌面圆角由 HarmonyOS 统一处理。

## 2. 范围

- 更新 `AppScope/resources/base/media/app_icon.png`。
- 更新 `entry/src/main/resources/base/media/app_icon.png`，保持 AppScope 与 entry 资源一致。
- 在 `docs/assets/` 保存一份 `1024x1024` 的高分辨率处理后资产，供应用市场资料复用。
- 保持 `AppScope/app.json5` 和 `entry/src/main/module.json5` 现有 `$media:app_icon` 引用不变。
- 不新增分层图标 JSON，不修改业务代码或应用配置；不把圆角作为新的装饰元素依赖。

## 3. 资源处理

- 输入图为不透明 RGB PNG，尺寸为 `1254x1254`；四角是实际黑色像素，不是透明区域。
- 以浅蓝纯色填充四角，生成不透明方形 PNG，避免黑角和透明背景在桌面或应用市场预览中出现。
- 保留水滴、水杯和绿叶主体，主体不超出安全区；仅沿输入图已有的圆角边界清理外侧角落，避免缩放后再次混入暗边或白边，桌面最终圆角仍由 HarmonyOS 处理。
- 输出两种尺寸：`1024x1024` 文档资产和 `192x192` 工程运行资源。
- 文件名只使用现有的 `app_icon.png`，不改变资源引用键。

## 4. 验证

- 使用图像元数据检查两个运行资源均为 `192x192`、PNG、四角不为黑色且无透明通道。
- 检查高分辨率资产为 `1024x1024` PNG。
- 检查 `app.json5` 与 entry 的 `module.json5` 仍引用 `$media:app_icon`。
- 执行项目现有的 release 构建命令，确认资源合并和 ArkTS 编译通过。

## 5. 依据与限制

华为 HarmonyOS 开发者文档的“配置应用图标和名称”说明了单层图标、分层图标、AppScope 资源目录及 UIAbility 图标优先级；该项目当前已使用单层图标并通过 AppScope 与 entry 同名资源统一引用。本次不引入分层资源，避免扩大变更范围。

官方文档入口：

https://developer.huawei.com/consumer/cn/doc/

具体尺寸 `1024x1024` 作为高分辨率提交资产的项目约定，不宣称为当前审核政策的唯一最低值；最终应用市场上传时仍应以提交页面当时显示的审核要求为准。
