import { router } from '@kit.ArkUI'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { DEFAULT_AVATAR_ID, avatarGlyph } from '../common/AvatarOptions'
import { ThemeColor, ThemeColors, getThemeColors, isSystemDarkMode, withAlpha } from '../common/Theme'
import { UiTokens } from '../common/Theme'
import { PreferencesService } from '../services/PreferencesService'
import { ThemedConfirmDialog } from '../components/ThemedConfirmDialog'
import { publishDataRefresh } from '../common/DataRefresh'
import { setLedgerDarkMode } from '../ledger/common/LedgerTheme'
import { AppSymbol } from '../components/AppSymbol'

interface ThemeChoice {
  id: ThemeColor
  color: string
}

@Component
export struct SettingsPage {
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @State currentThemeColor: ThemeColor = 'blue'
  @State dailyGoal: number = 2000
  @State nickname: string = ''
  @State avatarId: string = DEFAULT_AVATAR_ID
  @State showAboutDialog: boolean = false
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @StorageProp('refreshSignal') @Watch('onRefreshSignal') refreshSignal: number = 0

  private prefsService: PreferencesService = new PreferencesService(getContext(this))
  private readonly themeChoices: ThemeChoice[] = [
    { id: 'blue', color: '#007AFF' },
    { id: 'green', color: '#248A3D' },
    { id: 'purple', color: '#7B1FA2' },
    { id: 'orange', color: '#9A4C00' },
    { id: 'pink', color: '#C2185B' },
    { id: 'teal', color: '#00796B' }
  ]

  async aboutToAppear() {
    await this.loadSettings()
  }

  async onPageShow() {
    await this.loadSettings()
  }

  async onRefreshSignal() {
    await this.loadSettings()
  }

  async onColorModeChange() {
    await this.loadSettings()
  }

  private async loadSettings() {
    const settings = await this.prefsService.getSettings()
    this.currentThemeColor = settings.themeColor
    const dark = isSystemDarkMode(this.colorMode)
    this.themeColors = getThemeColors(dark, settings.themeColor)
    setLedgerDarkMode(dark)

    const profile = await this.prefsService.getProfile()
    this.dailyGoal = profile.dailyGoalMl
    this.nickname = profile.nickname
    this.avatarId = profile.avatarId
  }

  private async saveThemeColor(themeColor: ThemeColor) {
    const settings = await this.prefsService.getSettings()
    settings.themeColor = themeColor
    await this.prefsService.saveSettings(settings)
    publishDataRefresh()
  }

  private showAbout() {
    this.showAboutDialog = true
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
      Text('我的')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .width('100%')
        .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal, top: 16, bottom: 12 })

      Scroll() {
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            Stack({ alignContent: Alignment.Center }) {
              Circle().width(50).height(50).fill(withAlpha(this.themeColors.primary, '20'))
              AppSymbol({ name: avatarGlyph(this.avatarId), symbolSize: 24, color: this.themeColors.primaryText })
            }

            Column({ space: 4 }) {
              Text(this.nickname || '未设置昵称')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.textPrimary)
              Text(`每日目标 ${this.dailyGoal} ml`)
                .fontSize(13)
                .fontColor(this.themeColors.textSecondary)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            AppSymbol({ name: 'next', symbolSize: 16, color: this.themeColors.textSecondary })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.themeColors.card)
          .borderRadius(UiTokens.cardRadius)
          .onClick(() => { router.pushUrl({ url: 'pages/ProfilePage' }) })

          Column({ space: 2 }) {
            this.GoalSettingItem()
            this.SettingItem('beverage', '饮品管理', '', () => {
              router.pushUrl({ url: 'pages/BeveragePage' })
            })
            this.SettingItem('plant', '植物花园', '', () => {
              router.pushUrl({ url: 'pages/PlantGardenPage' })
            })
          }
          .width('100%')
          .backgroundColor(this.themeColors.card)
          .borderRadius(UiTokens.cardRadius)
          .clip(true)

          Column({ space: 2 }) {
            Text('财务管理')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textSecondary)
              .width('100%')
              .padding({ left: 16, top: 12, bottom: 4 })
            this.SettingItem('wallet', '账本统计', '', () => {
              router.pushUrl({ url: 'pages/ledger/LedgerStatisticsPage' })
            })
            this.SettingItem('grid', '分类管理', '', () => {
              router.pushUrl({ url: 'pages/ledger/LedgerCategoryManagePage' })
            })
            this.SettingItem('card', '月预算', '', () => {
              router.pushUrl({ url: 'pages/ledger/LedgerBudgetPage' })
            })
          }
          .width('100%')
          .backgroundColor(this.themeColors.card)
          .borderRadius(UiTokens.cardRadius)
          .clip(true)

          Column({ space: 2 }) {
            Text('数据与隐私')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textSecondary)
              .width('100%')
              .padding({ left: 16, top: 12, bottom: 4 })
            this.SettingItem('grid', '备份与数据管理', '', () => {
              router.pushUrl({ url: 'pages/DataManagePage' })
            })
          }
          .width('100%')
          .backgroundColor(this.themeColors.card)
          .borderRadius(UiTokens.cardRadius)
          .clip(true)

          Column({ space: 12 }) {
            Text('主题色')
              .fontSize(14)
              .fontColor(this.themeColors.textSecondary)
              .width('100%')

            Row({ space: 8 }) {
              ForEach(this.themeChoices, (choice: ThemeChoice) => {
                Stack({ alignContent: Alignment.Center }) {
                  Circle()
                    .width(46)
                    .height(46)
                    .fill(Color.Transparent)
                    .stroke(this.currentThemeColor === choice.id ? this.themeColors.textPrimary : Color.Transparent)
                    .strokeWidth(2)
                  Circle()
                    .width(34)
                    .height(34)
                    .fill(choice.color)
                }
                .width(UiTokens.colorPickerOptionSize)
                .height(UiTokens.colorPickerOptionSize)
                .onClick(() => { this.saveThemeColor(choice.id) })
              }, (choice: ThemeChoice) => choice.id)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.themeColors.card)
          .borderRadius(UiTokens.cardRadius)

          this.SettingItem('settings', '关于与协议', 'v1.0.0', () => {
            router.pushUrl({ url: 'pages/ProtocolPage' })
          })

          Column().height(20)
        }
        .constraintSize({ minHeight: '100%' })
        .justifyContent(FlexAlign.Start)
        .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.background)

      if (this.showAboutDialog) {
        ThemedConfirmDialog({
          title: '关于元气有数',
          message: '元气有数 v1.0.0\n\n喝水、记账与生活管理。',
          confirmText: '好的',
          showCancel: false,
          textColor: this.themeColors.textPrimary,
          secondaryTextColor: this.themeColors.textSecondary,
          cardColor: this.themeColors.card,
          surfaceColor: this.themeColors.surface,
          dividerColor: this.themeColors.divider,
          confirmColor: this.themeColors.primary,
          onConfirm: () => {
            this.showAboutDialog = false
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  GoalSettingItem() {
    Row({ space: 12 }) {
      AppSymbol({ name: 'water', symbolSize: 20, color: this.themeColors.primaryText })
        .width(42)

      Text('饮水目标')
        .fontSize(15)
        .fontColor(this.themeColors.textPrimary)
        .layoutWeight(1)

      Text(`${this.dailyGoal} ml`)
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)

      AppSymbol({ name: 'next', symbolSize: 16, color: this.themeColors.textSecondary })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => { router.pushUrl({ url: 'pages/GoalSettingsPage' }) })
  }

  @Builder
  SettingItem(icon: string, title: string, value: string, action: () => void) {
    Row({ space: 12 }) {
      AppSymbol({ name: icon, symbolSize: 20, color: this.themeColors.primaryText })
        .width(42)

      Text(title)
        .fontSize(15)
        .fontColor(this.themeColors.textPrimary)
        .layoutWeight(1)

      if (value) {
        Text(value)
          .fontSize(13)
          .fontColor(this.themeColors.textSecondary)
      }

      AppSymbol({ name: 'next', symbolSize: 16, color: this.themeColors.textSecondary })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(action)
  }
}
