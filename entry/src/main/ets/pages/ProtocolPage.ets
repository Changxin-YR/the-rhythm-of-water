import { router } from '@kit.ArkUI'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { getThemeColors, isSystemDarkMode, ThemeColors, UiTokens } from '../common/Theme'
import { PreferencesService } from '../services/PreferencesService'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'

@Entry
@Component
struct ProtocolPage {
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @StorageProp('safeAreaTop') safeAreaTop: number = 0
  private prefsService: PreferencesService = new PreferencesService(getContext(this))

  async aboutToAppear() {
    const settings = await this.prefsService.getSettings()
    this.themeColors = getThemeColors(isSystemDarkMode(this.colorMode), settings.themeColor)
  }

  async onColorModeChange() {
    const settings = await this.prefsService.getSettings()
    this.themeColors = getThemeColors(isSystemDarkMode(this.colorMode), settings.themeColor)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SystemSafeAreaBackground({ colors: this.themeColors })
      Column() {
        Row() {
          Text('‹')
            .width(44)
            .height(44)
            .fontSize(28)
            .fontColor(this.themeColors.textPrimary)
            .textAlign(TextAlign.Center)
            .onClick(() => { router.back() })

          Text('用户协议')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeColors.textPrimary)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Blank().width(44)
        }
        .width('100%')
        .height(56)
        .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal })

        Scroll() {
          Column({ space: 14 }) {
            Column({ space: 8 }) {
              Text('元气有数用户协议')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.primaryText)
              Text('生效日期：2026年8月12日')
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
            }
            .width('100%')
            .padding(18)
            .backgroundColor(this.themeColors.card)
            .border({ width: 1, color: this.themeColors.divider })
            .borderRadius(UiTokens.cardRadius)

            this.ProtocolCard('一、服务内容', '元气有数提供饮水记录、饮品管理、饮水目标、账本记录、月度预算、统计、植物和成就等本地生活管理功能。饮水与账本数据分别记录，您可按需要使用相应功能。')
            this.ProtocolCard('二、本地数据与备份', '您的饮水记录、账本记录、设置、成就和植物数据默认保存在本设备的应用沙箱中。您可主动使用数据管理功能备份、恢复或清除数据；清除后的数据无法恢复，请谨慎操作。')
            this.ProtocolCard('三、账本与预算', '账本、分类和月度预算用于记录个人收支及查看统计结果。记录和预算仅供个人参考，不构成财务、税务、投资或其他专业建议。请自行核对重要金额和分类信息。')
            this.ProtocolCard('四、使用规范', '请合理使用本应用，不要尝试干扰应用运行、绕过系统权限或使用非法方式处理应用数据。您应自行保管设备并定期备份重要数据。')
            this.ProtocolCard('五、免责声明', '在法律允许范围内，因设备故障、系统限制、权限变更、误操作、未备份数据或不可抗力造成的数据丢失或使用影响，元气有数不承担超出法律规定范围的责任。')
            this.ProtocolCard('六、协议变更', '功能或适用规则发生变化时，本协议可能同步更新。更新后的协议将在应用内展示；您继续使用本应用，即表示同意适用更新后的协议。')
            Column().height(24)
            Column().height(24)
          }
          .constraintSize({ minHeight: '100%' })
          .justifyContent(FlexAlign.Start)
          .width('100%')
          .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal, bottom: 16 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.safeAreaTop })
      .backgroundColor(this.themeColors.background)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ProtocolCard(title: string, body: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .width('100%')
      Text(body)
        .fontSize(14)
        .lineHeight(22)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.themeColors.card)
    .border({ width: 1, color: this.themeColors.divider })
    .borderRadius(UiTokens.cardRadius)
  }
}
