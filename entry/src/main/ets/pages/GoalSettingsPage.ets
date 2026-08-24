import { router } from '@kit.ArkUI'
import { GoalService } from '../services/GoalService'
import { PreferencesService } from '../services/PreferencesService'
import { GoalCalculator } from '../common/GoalCalculator'
import { UserProfile } from '../models/UserProfile'
import { Constants } from '../common/Constants'
import { getThemeColors, isSystemDarkMode, ThemeColors } from '../common/Theme'
import { UiTokens } from '../common/Theme'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'
import { SystemBarService } from '../services/SystemBarService'
import { publishDataRefresh } from '../common/DataRefresh'

@Entry
@Component
struct GoalSettingsPage {
  @State profile: UserProfile | null = null
  @State currentGoal: number = 2000
  @State calculatedGoal: number = 2000
  @State isAuto: boolean = true
  @State manualGoal: number = 2000
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @StorageProp('safeAreaTop') safeAreaTop: number = 0

  private goalService: GoalService = new GoalService(getContext(this))
  private prefsService: PreferencesService = new PreferencesService(getContext(this))
  private systemBarService: SystemBarService = new SystemBarService()

  async aboutToAppear() {
    await this.applyTheme()
    this.profile = await this.prefsService.getProfile()
    this.currentGoal = this.profile.dailyGoalMl
    this.isAuto = this.profile.isGoalAutoCalculated
    this.manualGoal = this.currentGoal
    this.calculatedGoal = GoalCalculator.calculate(
      this.profile.weightKg, this.profile.activityLevel, this.profile.specialState, this.profile.climate
    )
  }

  async onColorModeChange() {
    await this.applyTheme()
  }

  private async applyTheme() {
    const settings = await this.prefsService.getSettings()
    this.themeColors = getThemeColors(isSystemDarkMode(this.colorMode), settings.themeColor)
    await this.systemBarService.apply(getContext(this), this.themeColors)
  }

  private async save() {
    if (this.isAuto) {
      await this.goalService.setAutoGoal()
    } else {
      await this.goalService.setManualGoal(this.manualGoal)
    }
    publishDataRefresh()
    router.back()
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SystemSafeAreaBackground({ colors: this.themeColors })
      Column() {
      Row({ space: 12 }) {
        Text('←')
          .fontSize(24)
          .fontColor(this.themeColors.textPrimary)
          .onClick(() => { router.back() })
          .padding(8)

        Text('饮水目标')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .layoutWeight(1)

        Text('保存')
          .fontSize(15)
          .fontColor(this.themeColors.primaryText)
          .fontWeight(FontWeight.Medium)
          .onClick(() => { this.save() })
          .padding(8)
      }
      .width('100%')
      .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal, top: 16 + this.safeAreaTop })

      Scroll() {
        Column({ space: 16 }) {
          // Current goal display
          Column({ space: 8 }) {
            Text(`${this.isAuto ? this.calculatedGoal : this.manualGoal}`)
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.primaryText)

            Text('ml / 天')
              .fontSize(16)
              .fontColor(this.themeColors.textSecondary)
          }
          .width('100%')
          .padding(24)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.themeColors.card)
          .borderRadius(UiTokens.cardRadius)

          // Auto/Manual toggle
          Column({ space: 12 }) {
            Row() {
              Text('自动计算')
                .fontSize(15)
                .fontColor(this.themeColors.textPrimary)
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.isAuto })
                .selectedColor(this.themeColors.primary)
                .onChange((isOn: boolean) => { this.isAuto = isOn })
            }
            .width('100%')

            Text('根据体重、运动量和气候自动计算推荐饮水量')
              .fontSize(12)
              .fontColor(this.themeColors.textSecondary)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.themeColors.card)
          .borderRadius(UiTokens.cardRadius)

          // Manual slider
          if (!this.isAuto) {
            Column({ space: 12 }) {
              Text('手动设置目标')
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
                .width('100%')

              Slider({ value: this.manualGoal, min: Constants.MIN_GOAL_ML, max: Constants.MAX_GOAL_ML, step: 50 })
                .width('100%')
                .selectedColor(this.themeColors.primary)
                .onChange((v: number) => { this.manualGoal = Math.round(v) })

              Row() {
                Text(`${Constants.MIN_GOAL_ML}ml`)
                  .fontSize(12)
                  .fontColor(this.themeColors.textSecondary)
                Blank()
                Text(`${Constants.MAX_GOAL_ML}ml`)
                  .fontSize(12)
                  .fontColor(this.themeColors.textSecondary)
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.themeColors.card)
            .borderRadius(UiTokens.cardRadius)
          }

          // Formula explanation
          if (this.isAuto && this.profile) {
            Column({ space: 8 }) {
              Text('计算公式')
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
                .width('100%')

              Text(`基础量 = ${this.profile.weightKg}kg × 33 = ${this.profile.weightKg * 33}ml`)
                .fontSize(13)
                .fontColor(this.themeColors.textPrimary)

              Text(`运动调节系数：×${this.getMultiplierText()}`)
                .fontSize(13)
                .fontColor(this.themeColors.textPrimary)

              Text(`推荐目标：${this.calculatedGoal}ml`)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.primaryText)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.themeColors.card)
            .borderRadius(UiTokens.cardRadius)
          }

          Column().height(20)
        }
        .constraintSize({ minHeight: '100%' })
        .justifyContent(FlexAlign.Start)
        .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal, top: 12 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.background)
    }
    .width('100%')
    .height('100%')
  }

  private getMultiplierText(): string {
    if (!this.profile) return '1.0'
    switch (this.profile.activityLevel) {
      case 'sedentary': return '1.0'
      case 'light': return '1.1'
      case 'moderate': return '1.2'
      case 'active': return '1.3'
      case 'athlete': return '1.5'
    }
  }
}
