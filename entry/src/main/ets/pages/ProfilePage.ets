import { router } from '@kit.ArkUI'
import { PreferencesService } from '../services/PreferencesService'
import { GoalService } from '../services/GoalService'
import { UserProfile, ActivityLevel, SpecialState, ClimateType } from '../models/UserProfile'
import { getThemeColors, isSystemDarkMode, ThemeColors, withAlpha } from '../common/Theme'
import { UiTokens } from '../common/Theme'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { AVATAR_OPTIONS, AvatarOption, avatarGlyph } from '../common/AvatarOptions'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'
import { SystemBarService } from '../services/SystemBarService'
import { publishDataRefresh } from '../common/DataRefresh'
import { AppSymbol } from '../components/AppSymbol'

@Entry
@Component
struct ProfilePage {
  @State profile: UserProfile | null = null
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @State showAvatarPicker: boolean = false
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @StorageProp('safeAreaTop') safeAreaTop: number = 0

  private prefsService: PreferencesService = new PreferencesService(getContext(this))
  private goalService: GoalService = new GoalService(getContext(this))
  private systemBarService: SystemBarService = new SystemBarService()

  async aboutToAppear() {
    await this.applyTheme()
    this.profile = await this.prefsService.getProfile()
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
    if (this.profile) {
      await this.prefsService.saveProfile(this.profile)
      if (this.profile.isGoalAutoCalculated) {
        await this.goalService.calculateAndSaveGoal()
      }
    }
    publishDataRefresh()
    router.back()
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      SystemSafeAreaBackground({ colors: this.themeColors })
      Column() {
      Row({ space: 12 }) {
        Text('←')
          .fontSize(24)
          .fontColor(this.themeColors.textPrimary)
          .width(UiTokens.minimumTouchTargetSize)
          .height(UiTokens.minimumTouchTargetSize)
          .textAlign(TextAlign.Center)
          .onClick(() => { router.back() })

        Text('个人资料')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .layoutWeight(1)

        Text('保存')
          .fontSize(15)
          .fontColor(this.themeColors.primaryText)
          .fontWeight(FontWeight.Medium)
          .height(UiTokens.minimumTouchTargetSize)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.save() })
      }
      .width('100%')
      .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal, top: 16 + this.safeAreaTop })

      if (this.profile) {
        Scroll() {
          Column({ space: 16 }) {
            // Avatar
            Row({ space: 14 }) {
              Stack({ alignContent: Alignment.Center }) {
                Circle()
                  .width(64)
                  .height(64)
                  .fill(withAlpha(this.themeColors.primary, '20'))
                AppSymbol({ name: avatarGlyph(this.profile!.avatarId), symbolSize: 30, color: this.themeColors.primaryText })
              }

              Column({ space: 4 }) {
                Text('头像')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.themeColors.textPrimary)
                Text('更换头像')
                  .fontSize(13)
                  .fontColor(this.themeColors.textSecondary)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text('>')
                .fontSize(18)
                .fontColor(this.themeColors.textSecondary)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.themeColors.card)
            .borderRadius(20)
            .onClick(() => { this.showAvatarPicker = true })

            // Nickname
            Column({ space: 6 }) {
              Text('昵称')
                .fontSize(13)
                .fontColor(this.themeColors.textSecondary)
              TextInput({ text: this.profile.nickname, placeholder: '输入昵称' })
                .height(44)
                .fontColor(this.themeColors.textPrimary)
                .placeholderColor(this.themeColors.textPrimary)
                .backgroundColor(this.themeColors.input)
                .border({ width: 1, color: this.themeColors.divider })
                .borderRadius(10)
                .onChange((v: string) => { this.profile!.nickname = v })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.themeColors.card)
            .borderRadius(20)

            // Body info
            Column({ space: 16 }) {
              Text('身体信息')
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
                .width('100%')

              // Weight
              Column({ space: 4 }) {
                Row() {
                  Text('体重')
                    .fontSize(14)
                    .fontColor(this.themeColors.textPrimary)
                  Blank()
                  Text(`${this.profile.weightKg} kg`)
                    .fontSize(14)
                    .fontColor(this.themeColors.primaryText)
                }
                .width('100%')
                Slider({ value: this.profile.weightKg, min: 30, max: 150, step: 1 })
                  .selectedColor(this.themeColors.primary)
                  .onChange((v: number) => { this.profile!.weightKg = Math.round(v) })
              }

            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.themeColors.card)
            .borderRadius(20)

            // Activity
            Column({ space: 12 }) {
              Text('运动量')
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
                .width('100%')

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(
                  [['sedentary', '久坐'], ['light', '轻度'], ['moderate', '中度'], ['active', '高强度'], ['athlete', '运动员']] as string[][],
                  (item: string[]) => {
                    Text(item[1])
                      .fontSize(13)
                      .height(UiTokens.minimumTouchTargetSize)
                      .textAlign(TextAlign.Center)
                      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                      .backgroundColor(this.profile!.activityLevel === item[0] ? this.themeColors.primary : this.themeColors.surface)
                      .fontColor(this.profile!.activityLevel === item[0] ? this.themeColors.onPrimary : this.themeColors.textPrimary)
                      .borderRadius(16)
                      .margin(4)
                      .onClick(() => { this.profile!.activityLevel = item[0] as ActivityLevel })
                  },
                  (item: string[]) => item[0]
                )
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.themeColors.card)
            .borderRadius(20)

            // Special state
            Column({ space: 12 }) {
              Text('特殊状态')
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
                .width('100%')

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(
                  [['none', '无'], ['pregnant', '孕期'], ['breastfeeding', '哺乳期'], ['sick', '生病']] as string[][],
                  (item: string[]) => {
                    Text(item[1])
                      .fontSize(13)
                      .height(UiTokens.minimumTouchTargetSize)
                      .textAlign(TextAlign.Center)
                      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                      .backgroundColor(this.profile!.specialState === item[0] ? this.themeColors.primary : this.themeColors.surface)
                      .fontColor(this.profile!.specialState === item[0] ? this.themeColors.onPrimary : this.themeColors.textPrimary)
                      .borderRadius(16)
                      .margin(4)
                      .onClick(() => { this.profile!.specialState = item[0] as SpecialState })
                  },
                  (item: string[]) => item[0]
                )
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.themeColors.card)
            .borderRadius(20)

            // Climate
            Column({ space: 12 }) {
              Text('气候环境')
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
                .width('100%')

              Row({ space: 8 }) {
                ForEach(
                  [['normal', '正常'], ['hot', '炎热'], ['dry', '干燥']] as string[][],
                  (item: string[]) => {
                    Text(item[1])
                      .fontSize(13)
                      .height(UiTokens.minimumTouchTargetSize)
                      .textAlign(TextAlign.Center)
                      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                      .backgroundColor(this.profile!.climate === item[0] ? this.themeColors.primary : this.themeColors.surface)
                      .fontColor(this.profile!.climate === item[0] ? this.themeColors.onPrimary : this.themeColors.textPrimary)
                      .borderRadius(16)
                      .onClick(() => { this.profile!.climate = item[0] as ClimateType })
                  },
                  (item: string[]) => item[0]
                )
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.themeColors.card)
            .borderRadius(20)

            Column().height(20)
          }
          .constraintSize({ minHeight: '100%' })
          .justifyContent(FlexAlign.Start)
          .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal, top: 12 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.background)

      if (this.showAvatarPicker) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.themeColors.dialogOverlay)
          .onClick(() => { this.showAvatarPicker = false })

        Column({ space: 16 }) {
          Row() {
            Text('选择头像')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
              .layoutWeight(1)
            Text('取消')
              .fontSize(15)
              .fontColor(this.themeColors.primaryText)
              .height(UiTokens.minimumTouchTargetSize)
              .textAlign(TextAlign.Center)
              .onClick(() => { this.showAvatarPicker = false })
          }
          .width('100%')

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceAround }) {
            ForEach(AVATAR_OPTIONS, (option: AvatarOption): void => {
              Stack({ alignContent: Alignment.Center }) {
                Circle()
                  .width(56)
                  .height(56)
                  .fill(this.profile!.avatarId === option.id ? withAlpha(this.themeColors.primary, '20') : this.themeColors.surface)
                  .border({
                    width: this.profile!.avatarId === option.id ? 2 : 0,
                    color: this.themeColors.primary
                  })
                AppSymbol({ name: option.glyph, symbolSize: 28, color: this.themeColors.primaryText })
              }
              .width(64)
              .height(64)
              .margin(4)
              .onClick(() => {
                this.profile!.avatarId = option.id
                this.showAvatarPicker = false
              })
            }, (option: AvatarOption): string => option.id)
          }
          .width('100%')
        }
        .width('100%')
        .padding(20)
        .backgroundColor(this.themeColors.card)
        .borderRadius(20)
      }
    }
    .width('100%')
    .height('100%')
  }
}
