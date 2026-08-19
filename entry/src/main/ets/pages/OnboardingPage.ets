import { router } from '@kit.ArkUI'
import { PreferencesService } from '../services/PreferencesService'
import { GoalService } from '../services/GoalService'
import { PlantService } from '../services/PlantService'
import { UserProfile, DEFAULT_PROFILE, cloneUserProfile, ActivityLevel } from '../models/UserProfile'
import { GoalCalculator } from '../common/GoalCalculator'
import { getThemeColors, isSystemDarkMode, ThemeColors, UiTokens } from '../common/Theme'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'
import { SystemBarService } from '../services/SystemBarService'
import { AppSymbol } from '../components/AppSymbol'

@Entry
@Component
struct OnboardingPage {
  @State step: number = 0
  @State profile: UserProfile = cloneUserProfile(DEFAULT_PROFILE)
  @State calculatedGoal: number = 2000
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @StorageProp('safeAreaTop') safeAreaTop: number = 0

  private prefsService: PreferencesService = new PreferencesService(getContext(this))
  private goalService: GoalService = new GoalService(getContext(this))
  private plantService: PlantService = new PlantService(getContext(this))
  private systemBarService: SystemBarService = new SystemBarService()

  async aboutToAppear() {
    const settings = await this.prefsService.getSettings()
    this.themeColors = getThemeColors(isSystemDarkMode(this.colorMode), settings.themeColor)
    await this.systemBarService.apply(getContext(this), this.themeColors)
    this.recalculateGoal()
  }

  async onColorModeChange() {
    const settings = await this.prefsService.getSettings()
    this.themeColors = getThemeColors(isSystemDarkMode(this.colorMode), settings.themeColor)
    await this.systemBarService.apply(getContext(this), this.themeColors)
  }

  private recalculateGoal() {
    this.calculatedGoal = GoalCalculator.calculate(
      this.profile.weightKg,
      this.profile.activityLevel,
      this.profile.specialState,
      this.profile.climate
    )
  }

  private async finish() {
    this.profile.dailyGoalMl = this.calculatedGoal
    this.profile.isGoalAutoCalculated = true
    this.profile.onboardingCompleted = true
    this.profile.createdAt = Date.now()
    this.profile.updatedAt = Date.now()
    await this.prefsService.saveProfile(this.profile)
    await this.plantService.createPlant('sunflower', '我的向日葵')
    router.replaceUrl({ url: 'pages/MainPage' })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SystemSafeAreaBackground({ colors: this.themeColors })
      Column() {
      // Progress indicator
      Row({ space: 6 }) {
        ForEach([0, 1, 2], (i: number) => {
          Column()
            .height(4)
            .layoutWeight(1)
            .backgroundColor(i <= this.step ? this.themeColors.primary : this.themeColors.progressTrack)
            .borderRadius(2)
        }, (i: number) => i.toString())
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16 + this.safeAreaTop })

      Scroll() {
        Column({ space: 24 }) {
          if (this.step === 0) {
            this.WelcomeStep()
          } else if (this.step === 1) {
            this.ProfileStep()
          } else {
            this.GoalStep()
          }
        }
        .constraintSize({ minHeight: '100%' })
        .justifyContent(FlexAlign.Start)
        .padding({ left: 24, right: 24, top: 40 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // Bottom buttons
      Row({ space: 12 }) {
        if (this.step > 0) {
          Button('上一步')
            .fontSize(16)
            .fontColor(this.themeColors.textPrimary)
            .backgroundColor(this.themeColors.surface)
            .height(48)
            .layoutWeight(1)
            .borderRadius(14)
            .onClick(() => { this.step-- })
        }

        Button(this.step === 2 ? '开始使用' : '下一步')
          .fontSize(16)
          .fontColor(this.themeColors.onPrimary)
          .backgroundColor(this.themeColors.primary)
          .height(48)
          .layoutWeight(1)
          .borderRadius(14)
          .onClick(() => {
            if (this.step < 2) {
              this.step++
              if (this.step === 2) this.recalculateGoal()
            } else {
              this.finish()
            }
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.background)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  WelcomeStep() {
    Column({ space: 16 }) {
      AppSymbol({ name: 'water', symbolSize: 68, color: this.themeColors.primary })

      Text('欢迎使用元气有数')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)

      Text('记录饮水，养成习惯')
        .fontSize(16)
        .fontColor(this.themeColors.textSecondary)

      Text('我们会根据你填写的信息估算每日目标，结果仅作日常记录参考；如有特殊健康情况，请遵循专业人士建议。')
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .margin({ top: 16 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ProfileStep() {
    Column({ space: 20 }) {
      Text('基本信息')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .width('100%')

      // Nickname
      Column({ space: 6 }) {
        Text('昵称')
          .fontSize(13)
          .fontColor(this.themeColors.textSecondary)
        TextInput({ placeholder: '输入你的昵称', text: this.profile.nickname })
          .height(44)
          .fontColor(this.themeColors.textPrimary)
          .placeholderColor(this.themeColors.textPrimary)
          .backgroundColor(this.themeColors.input)
          .border({ width: 1, color: this.themeColors.divider })
          .borderRadius(10)
          .onChange((val: string) => { this.profile.nickname = val })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // Weight
      Column({ space: 6 }) {
        Text(`体重: ${this.profile.weightKg} kg`)
          .fontSize(13)
          .fontColor(this.themeColors.textSecondary)
        Slider({ value: this.profile.weightKg, min: 30, max: 150, step: 1 })
          .width('100%')
          .trackColor(this.themeColors.progressTrack)
          .selectedColor(this.themeColors.primary)
          .onChange((val: number) => { this.profile.weightKg = Math.round(val) })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // Activity Level
      Column({ space: 6 }) {
        Text('运动量')
          .fontSize(13)
          .fontColor(this.themeColors.textSecondary)
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(
            [['sedentary', '久坐'], ['light', '轻度'], ['moderate', '中度'], ['active', '高强度'], ['athlete', '运动员']] as string[][],
            (item: string[]) => {
              Text(item[1])
                .fontSize(13)
                .height(UiTokens.minimumTouchTargetSize)
                .textAlign(TextAlign.Center)
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .backgroundColor(this.profile.activityLevel === item[0] ? this.themeColors.primary : this.themeColors.surface)
                .fontColor(this.profile.activityLevel === item[0] ? this.themeColors.onPrimary : this.themeColors.textPrimary)
                .borderRadius(16)
                .margin(4)
                .onClick(() => { this.profile.activityLevel = item[0] as ActivityLevel })
            },
            (item: string[]) => item[0]
          )
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  GoalStep() {
    Column({ space: 20 }) {
      Text('你的每日目标')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .width('100%')

      Column({ space: 8 }) {
        Text(`${this.calculatedGoal}`)
          .fontSize(56)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.primaryText)

        Text('毫升 / 天')
          .fontSize(16)
          .fontColor(this.themeColors.textSecondary)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding(24)

      Text('根据你的体重和运动量，我们为你推荐了以上饮水目标。你可以稍后在设置中调整。')
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
        .lineHeight(22)
    }
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
      Blank()
      Text(value)
        .fontSize(14)
        .fontColor(this.themeColors.textPrimary)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }

  private getActivityName(): string {
    switch (this.profile.activityLevel) {
      case 'sedentary': return '久坐'
      case 'light': return '轻度活动'
      case 'moderate': return '中度活动'
      case 'active': return '高强度'
      case 'athlete': return '运动员'
    }
  }
}
