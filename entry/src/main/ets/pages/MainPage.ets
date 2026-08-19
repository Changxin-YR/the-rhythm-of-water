import { router, promptAction } from '@kit.ArkUI'
import { PreferencesService } from '../services/PreferencesService'
import { getThemeColors, isSystemDarkMode, ThemeColors, withAlpha } from '../common/Theme'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { HomePage } from './HomePage'
import { LedgerHomePage } from '../ledger/pages/LedgerHomePage'
import { SettingsPage } from './SettingsPage'
import { OverviewPage } from './OverviewPage'
import { WaterHubPage } from './WaterHubPage'
import { UiTokens } from '../common/Theme'
import { SystemBarService } from '../services/SystemBarService'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'
import { nextRefreshRevision, shouldRefreshAchievementOnTabSelection } from '../common/DataRefresh'
import { minimumBottomControlInsetVp } from '../common/SafeAreaRules'
import { LedgerRefreshBridge } from '../services/LedgerRefreshBridge'
import { setLedgerDarkMode } from '../ledger/common/LedgerTheme'
import { AppSymbol } from '../components/AppSymbol'

interface TabItem {
  label: string
}

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0
  @State achievementRefreshRevision: number = 0
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @StorageProp('refreshSignal') @Watch('onRefreshSignal') refreshSignal: number = 0
  @StorageProp('safeAreaTop') safeAreaTop: number = 0
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0
  private prefsService: PreferencesService = new PreferencesService(getContext(this))
  private systemBarService: SystemBarService = new SystemBarService()

  private tabItems: TabItem[] = [
    { label: '概览' },
    { label: '喝水' },
    { label: '账本' },
    { label: '我的' }
  ]

  async aboutToAppear() {
    LedgerRefreshBridge.install()
    try {
      const settings = await this.prefsService.getSettings()
      const dark = isSystemDarkMode(this.colorMode)
      setLedgerDarkMode(dark)
      this.themeColors = getThemeColors(dark, settings.themeColor)
      await this.systemBarService.apply(getContext(this), this.themeColors)

      const profile = await this.prefsService.getProfile()
      if (!profile.onboardingCompleted) {
        router.pushUrl({ url: 'pages/OnboardingPage' })
      }
    } catch (error) {
      promptAction.showToast({ message: '本地数据初始化失败，已使用默认设置' })
      this.themeColors = getThemeColors(false, 'blue')
      setLedgerDarkMode(false)
      await this.systemBarService.apply(getContext(this), this.themeColors)
    }
  }

  async onColorModeChange() {
    await this.reloadTheme()
  }

  async onRefreshSignal() {
    await this.reloadTheme()
  }

  private selectTab(index: number): void {
    const shouldRefreshAchievements = shouldRefreshAchievementOnTabSelection(this.currentIndex, index)
    this.currentIndex = index
    if (shouldRefreshAchievements) {
      this.achievementRefreshRevision = nextRefreshRevision(this.achievementRefreshRevision)
    }
  }

  private bottomControlInset(): number {
    return minimumBottomControlInsetVp(this.safeAreaBottom)
  }

  private async reloadTheme() {
    try {
      const settings = await this.prefsService.getSettings()
      const dark = isSystemDarkMode(this.colorMode)
      setLedgerDarkMode(dark)
      this.themeColors = getThemeColors(dark, settings.themeColor)
      await this.systemBarService.apply(getContext(this), this.themeColors)
    } catch (e) {
      console.error('MainPage: failed to reload theme', JSON.stringify(e))
      this.themeColors = getThemeColors(false, 'blue')
      setLedgerDarkMode(false)
      await this.systemBarService.apply(getContext(this), this.themeColors)
    }
  }

  @Builder
  TabBuilder(index: number) {
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.Center }) {
        if (index === 0) {
          AppSymbol({ name: 'overview', symbolSize: UiTokens.bottomBarIconSize, color: index === this.currentIndex ? this.themeColors.primaryText : this.themeColors.textSecondary })
        } else if (index === 1) {
          SymbolGlyph($r('sys.symbol.drop_fill'))
            .fontSize(UiTokens.bottomBarIconSize)
            .fontColor([index === this.currentIndex ? this.themeColors.primaryText : this.themeColors.textSecondary])
        } else if (index === 2) {
          SymbolGlyph($r('sys.symbol.wallet_fill'))
            .fontSize(UiTokens.bottomBarIconSize)
            .fontColor([index === this.currentIndex ? this.themeColors.primaryText : this.themeColors.textSecondary])
        } else {
          AppSymbol({ name: 'person', symbolSize: UiTokens.bottomBarIconSize, color: index === this.currentIndex ? this.themeColors.primaryText : this.themeColors.textSecondary })
        }
      }
      .width('100%')
      .height(UiTokens.bottomBarIconBoxHeight)
      .scale({ x: index === this.currentIndex ? 1.05 : 0.96, y: index === this.currentIndex ? 1.05 : 0.96 })
      .animation({ duration: 180, curve: Curve.EaseOut })

      Text(this.tabItems[index].label)
        .fontSize(UiTokens.bottomBarLabelSize)
        .fontColor(index === this.currentIndex ? this.themeColors.primaryText : this.themeColors.textSecondary)
        .width('100%')
        .height(UiTokens.bottomBarLabelBoxHeight)
        .lineHeight(UiTokens.bottomBarLabelBoxHeight)
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height(UiTokens.bottomBarHeight)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.selectTab(index)
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SystemSafeAreaBackground({ colors: this.themeColors })

      Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.currentIndex === 0) {
          Column() {
            OverviewPage({
              options: {
                onOpenWater: () => { this.currentIndex = 1 },
                onOpenLedger: () => { this.currentIndex = 2 },
                onOpenSettings: () => { this.currentIndex = 3 }
              }
            })
          }
          .width('100%')
          .height('100%')
        } else if (this.currentIndex === 1) {
          Column() {
            WaterHubPage()
          }
          .width('100%')
          .height('100%')
        } else if (this.currentIndex === 2) {
          Column() {
            LedgerHomePage()
          }
          .width('100%')
          .height('100%')
        } else {
          Column() {
            SettingsPage()
          }
          .width('100%')
          .height('100%')
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ top: this.safeAreaTop })

      Column() {
        Row() {
          this.TabBuilder(0)
          this.TabBuilder(1)
          this.TabBuilder(2)
          this.TabBuilder(3)
        }
        .height(UiTokens.bottomBarHeight)
        .width('100%')
      }
      .height(UiTokens.bottomBarHeight + this.bottomControlInset())
      .padding({ bottom: this.bottomControlInset() })
      .width('100%')
      .backgroundColor(withAlpha(this.themeColors.card, 'F2'))
    }
    .backgroundColor(this.themeColors.background)
    .width('100%')
    .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
