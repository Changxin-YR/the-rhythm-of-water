import { router } from '@kit.ArkUI'
import { AchievementService } from '../services/AchievementService'
import { DrinkService } from '../services/DrinkService'
import { GoalService } from '../services/GoalService'
import { PlantService } from '../services/PlantService'
import { PreferencesService } from '../services/PreferencesService'
import { Achievement, LEVEL_THRESHOLDS, LevelInfo } from '../models/Achievement'
import { Plant } from '../models/Plant'
import { AchievementCard } from '../components/AchievementCard'
import { PlantView } from '../components/PlantView'
import { getThemeColors, isSystemDarkMode, ThemeColors } from '../common/Theme'
import { UiTokens } from '../common/Theme'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { getAchievementDisplayMetrics } from '../common/DashboardData'
import { nextRefreshRevision } from '../common/DataRefresh'
import { PageHeader } from '../components/PageHeader'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'
import { AppSymbol } from '../components/AppSymbol'

@Entry
@Component
struct AchievementPage {
  @State achievements: Achievement[] = []
  @State currentPlant: Plant | null = null
  @State totalVolume: number = 0
  @State currentLevel: LevelInfo = LEVEL_THRESHOLDS[0]
  @State nextLevel: LevelInfo | null = LEVEL_THRESHOLDS[1]
  @State streak: number = 0
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @State achievementCardRevision: number = 0
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @StorageProp('refreshSignal') @Watch('onRefreshSignal') refreshSignal: number = 0

  private achievementService: AchievementService = new AchievementService(getContext(this))
  private drinkService: DrinkService = new DrinkService(getContext(this))
  private goalService: GoalService = new GoalService(getContext(this))
  private plantService: PlantService = new PlantService(getContext(this))
  private prefsService: PreferencesService = new PreferencesService(getContext(this))

  async aboutToAppear() {
    await this.loadTheme()
    await this.refresh()
  }

  async onColorModeChange() {
    await this.loadTheme()
  }

  async onPageShow() {
    await this.refresh()
  }

  async onRefreshSignal() {
    await this.loadTheme()
    await this.refresh()
  }

  private async loadTheme() {
    const settings = await this.prefsService.getSettings()
    const dark = isSystemDarkMode(this.colorMode)
    this.themeColors = getThemeColors(dark, settings.themeColor)
  }

  private async refresh() {
    const goalMl = await this.goalService.getGoal()
    // Use this calculation's result directly, then remount cards to avoid stale reused props.
    this.achievements = await this.achievementService.checkAndUpdate(goalMl)
    this.achievementCardRevision = nextRefreshRevision(this.achievementCardRevision)
    this.currentPlant = await this.plantService.getActivePlant()
    this.totalVolume = await this.drinkService.getTotalVolume()
    this.streak = await this.drinkService.getStreak(goalMl)
    const displayMetrics = getAchievementDisplayMetrics(this.totalVolume, this.streak, this.currentPlant?.waterReceived ?? 0)
    this.totalVolume = displayMetrics.totalVolume
    this.streak = displayMetrics.streak
    this.calculateLevel()
  }

  private calculateLevel() {
    for (let i = LEVEL_THRESHOLDS.length - 1; i >= 0; i--) {
      if (this.totalVolume >= LEVEL_THRESHOLDS[i].minVolumeMl) {
        this.currentLevel = LEVEL_THRESHOLDS[i]
        this.nextLevel = i < LEVEL_THRESHOLDS.length - 1 ? LEVEL_THRESHOLDS[i + 1] : null
        break
      }
    }
  }

  private getLevelProgress(): number {
    if (!this.nextLevel) return 100
    const current = this.totalVolume - this.currentLevel.minVolumeMl
    const range = this.nextLevel.minVolumeMl - this.currentLevel.minVolumeMl
    return range > 0 ? Math.round((current / range) * 100) : 100
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SystemSafeAreaBackground({ colors: this.themeColors })
      Column() {
        PageHeader({
          title: '成就',
          textColor: this.themeColors.textPrimary,
          onBack: () => { router.back() }
        })

        Scroll() {
        Column({ space: 16 }) {
          // Streak & Level card
          Row({ space: 16 }) {
            Column({ space: 6 }) {
              AppSymbol({ name: 'fire', symbolSize: 28, color: this.themeColors.warning })
              Text(`${this.streak}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.textPrimary)
              Text('连续天数')
                .fontSize(12)
                .fontColor(this.themeColors.textSecondary)
            }
            .layoutWeight(1)
            .padding(16)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.themeColors.card)
            .borderRadius(UiTokens.cardRadius)

            Column({ space: 6 }) {
              AppSymbol({ name: this.currentLevel.icon, symbolSize: 28, color: this.themeColors.primaryText })
              Text(this.currentLevel.name)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.textPrimary)
              Text(`累计 ${Math.round(this.totalVolume / 10) / 100}L`)
                .fontSize(12)
                .fontColor(this.themeColors.textSecondary)
            }
            .layoutWeight(1)
            .padding(16)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.themeColors.card)
            .borderRadius(UiTokens.cardRadius)
          }
          .width('100%')

          // Level progress
          if (this.nextLevel) {
            Column({ space: 6 }) {
              Row() {
                Row({ space: 4 }) {
                  AppSymbol({ name: this.currentLevel.icon, symbolSize: 14, color: this.themeColors.textSecondary })
                  Text(this.currentLevel.name).fontSize(12).fontColor(this.themeColors.textSecondary)
                }
                Blank()
                Row({ space: 4 }) {
                  AppSymbol({ name: this.nextLevel.icon, symbolSize: 14, color: this.themeColors.textSecondary })
                  Text(this.nextLevel.name).fontSize(12).fontColor(this.themeColors.textSecondary)
                }
              }
              .width('100%')

              Progress({ value: this.getLevelProgress(), total: 100, type: ProgressType.Linear })
                .width('100%')
                .height(8)
                .color(this.themeColors.primary)
                .backgroundColor(this.themeColors.progressTrack)
                .borderRadius(4)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.themeColors.card)
            .borderRadius(UiTokens.cardRadius)
          }

          // Plant section
          PlantView({
            plant: this.currentPlant,
            primaryColor: this.themeColors.primary,
            cardColor: this.themeColors.card,
            textColor: this.themeColors.textPrimary,
            textSecondary: this.themeColors.textSecondary,
            trackColor: this.themeColors.progressTrack,
            warningColor: this.themeColors.warning
          })

          // Achievements list
          Column({ space: 8 }) {
            Text('成就徽章')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textPrimary)
              .width('100%')

            ForEach(this.achievements, (item: Achievement) => {
              AchievementCard({
                achievement: item,
                primaryColor: this.themeColors.primary,
                primaryTextColor: this.themeColors.primaryText,
                cardColor: this.themeColors.card,
                textColor: this.themeColors.textPrimary,
                textSecondary: this.themeColors.textSecondary,
                trackColor: this.themeColors.progressTrack
              })
            }, (item: Achievement) => `${item.id}-${this.achievementCardRevision}`)
          }
          .width('100%')

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
    }
    .width('100%')
    .height('100%')
  }
}
