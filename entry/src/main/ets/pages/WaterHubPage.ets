import { router } from '@kit.ArkUI'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { HomePage } from './HomePage'
import { getThemeColors, isSystemDarkMode, ThemeColors, UiTokens } from '../common/Theme'
import { PreferencesService } from '../services/PreferencesService'
import { AppSymbol } from '../components/AppSymbol'

@Component
export struct WaterHubPage {
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @StorageProp('refreshSignal') @Watch('onRefreshSignal') refreshSignal: number = 0

  private prefsService: PreferencesService = new PreferencesService(getContext(this))

  async aboutToAppear() {
    const settings = await this.prefsService.getSettings()
    this.themeColors = getThemeColors(isSystemDarkMode(this.colorMode), settings.themeColor)
  }

  async onColorModeChange() {
    await this.reloadTheme()
  }

  async onRefreshSignal() {
    await this.reloadTheme()
  }

  private async reloadTheme() {
    const settings = await this.prefsService.getSettings()
    this.themeColors = getThemeColors(isSystemDarkMode(this.colorMode), settings.themeColor)
  }

  build() {
    Column() {
      Row({ space: 10 }) {
        Text('喝水')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .layoutWeight(1)
        Button({ type: ButtonType.Normal }) {
          Row({ space: 6 }) {
            AppSymbol({ name: 'calendar', symbolSize: 18, color: this.themeColors.primaryText })
            Text('统计').fontSize(14).fontColor(this.themeColors.primaryText)
          }
        }
          .height(UiTokens.recommendedTouchTargetSize)
          .padding({ left: 10, right: 10 })
          .backgroundColor(Color.Transparent)
          .onClick(() => { router.pushUrl({ url: 'pages/StatsPage' }) })
        Button({ type: ButtonType.Normal }) {
          Row({ space: 6 }) {
            AppSymbol({ name: 'achievement', symbolSize: 18, color: this.themeColors.primaryText })
            Text('成就').fontSize(14).fontColor(this.themeColors.primaryText)
          }
        }
          .height(UiTokens.recommendedTouchTargetSize)
          .padding({ left: 10, right: 10 })
          .backgroundColor(Color.Transparent)
          .onClick(() => { router.pushUrl({ url: 'pages/AchievementPage' }) })
      }
      .width('100%')
      .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal, top: 12, bottom: 6 })
      .backgroundColor(this.themeColors.background)

      Column() {
        HomePage()
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
  }
}
