import { router } from '@kit.ArkUI'
import { StatsService } from '../services/StatsService'
import { GoalService } from '../services/GoalService'
import { PreferencesService } from '../services/PreferencesService'
import { DailySummary, WeeklyStats, MonthlyStats, PeriodBreakdown } from '../models/DailySummary'
import { StatsBarChart } from '../components/StatsBarChart'
import { HeatmapCalendar } from '../components/HeatmapCalendar'
import { DateUtils } from '../common/DateUtils'
import { getThemeColors, isSystemDarkMode, ThemeColors } from '../common/Theme'
import { UiTokens } from '../common/Theme'
import { SegmentedControl } from '../components/SegmentedControl'
import { PageHeader } from '../components/PageHeader'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { AppSymbol } from '../components/AppSymbol'

@Entry
@Component
struct StatsPage {
  @State currentTab: number = 0
  @State weeklyStats: WeeklyStats = { days: [], avgMl: 0, goalDays: 0, totalDays: 0 }
  @State monthlyStats: MonthlyStats = { days: [], avgMl: 0, goalDays: 0, totalDays: 0 }
  @State yearlyStats: MonthlyStats = { days: [], avgMl: 0, goalDays: 0, totalDays: 0 }
  @State periodBreakdown: PeriodBreakdown = { morning: 0, afternoon: 0, evening: 0 }
  @State beverageBreakdown: Record<string, number> = {}
  @State goalMl: number = 2000
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @StorageProp('refreshSignal') @Watch('onRefreshSignal') refreshSignal: number = 0

  private statsService: StatsService = new StatsService(getContext(this))
  private goalService: GoalService = new GoalService(getContext(this))
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
    this.goalMl = await this.goalService.getGoal()
    this.weeklyStats = await this.statsService.getWeeklyStats(this.goalMl)
    this.monthlyStats = await this.statsService.getMonthlyStats(this.goalMl)
    this.yearlyStats = await this.statsService.getYearlyStats(this.goalMl)
    this.periodBreakdown = await this.statsService.getPeriodBreakdown(DateUtils.getToday())
    this.beverageBreakdown = await this.statsService.getBeverageBreakdown(DateUtils.getToday())
  }

  private getWeekLabels(): string[] {
    return ['一', '二', '三', '四', '五', '六', '日']
  }

  private getCurrentStats(): MonthlyStats {
    if (this.currentTab === 0) return this.weeklyStats
    if (this.currentTab === 1) return this.monthlyStats
    return this.yearlyStats
  }

  private getPeriodTotal(): number {
    return this.periodBreakdown.morning + this.periodBreakdown.afternoon + this.periodBreakdown.evening
  }

  private getPeriodPercent(value: number): number {
    const total = this.getPeriodTotal()
    return total > 0 ? Math.round((value / total) * 100) : 0
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SystemSafeAreaBackground({ colors: this.themeColors })
      Column() {
        PageHeader({
          title: '统计',
          textColor: this.themeColors.textPrimary,
          onBack: () => { router.back() }
        })

        SegmentedControl({
          labels: ['本周', '本月', '本年'],
          selectedIndex: this.currentTab,
          primaryColor: this.themeColors.primary,
          textSecondary: this.themeColors.textSecondary,
          trackColor: this.themeColors.surface,
          onChange: (index: number) => { this.currentTab = index }
        })
        .margin({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal, bottom: 12 })

        Scroll() {
        Column({ space: 16 }) {
          // Bar Chart
          Column({ space: 8 }) {
            if (this.currentTab === 0) {
              StatsBarChart({
                data: this.weeklyStats.days,
                goalMl: this.goalMl,
                primaryColor: this.themeColors.primary,
                secondaryColor: this.themeColors.secondary,
                textColor: this.themeColors.textPrimary,
                textSecondary: this.themeColors.textSecondary,
                labels: this.getWeekLabels()
              })
            } else if (this.currentTab === 1) {
              HeatmapCalendar({
                data: this.monthlyStats.days,
                primaryColor: this.themeColors.primary,
                cardColor: this.themeColors.card,
                textColor: this.themeColors.textPrimary,
                textSecondary: this.themeColors.textSecondary,
                trackColor: this.themeColors.progressTrack
              })
            } else {
              HeatmapCalendar({
                data: this.yearlyStats.days,
                primaryColor: this.themeColors.primary,
                cardColor: this.themeColors.card,
                textColor: this.themeColors.textPrimary,
                textSecondary: this.themeColors.textSecondary,
                trackColor: this.themeColors.progressTrack
              })
            }
          }
          .width('100%')
          .backgroundColor(this.themeColors.card)
          .borderRadius(UiTokens.cardRadius)
          .padding(8)

          // Summary cards
          Row({ space: 12 }) {
            this.StatCard('达标天数', '__goal_days__', 'calendar')
            this.StatCard('日均', '__average__', 'water')
          }
          .width('100%')

          // Period breakdown
          Column({ space: 12 }) {
            Text('时段分析')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textPrimary)
              .width('100%')

            this.PeriodBar('上午', 'morning')
            this.PeriodBar('下午', 'afternoon')
            this.PeriodBar('晚上', 'evening')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.themeColors.card)
          .borderRadius(UiTokens.cardRadius)

          // Beverage breakdown
          Column({ space: 12 }) {
            Text('饮品构成')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textPrimary)
              .width('100%')

            ForEach(Object.keys(this.beverageBreakdown), (key: string) => {
              Row({ space: 8 }) {
                Text(key)
                  .fontSize(14)
                  .fontColor(this.themeColors.textPrimary)
                  .layoutWeight(1)
                Text(`${this.beverageBreakdown[key]}ml`)
                  .fontSize(14)
                  .fontColor(this.themeColors.textSecondary)
              }
              .width('100%')
            }, (key: string) => key)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.themeColors.card)
          .borderRadius(UiTokens.cardRadius)

          Column().height(20)
        }
        .constraintSize({ minHeight: '100%' })
        .justifyContent(FlexAlign.Start)
        .padding({ left: 20, right: 20 })
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

  @Builder
  StatCard(label: string, value: string, icon: string) {
    Column({ space: 6 }) {
      AppSymbol({ name: icon, symbolSize: 22, color: this.themeColors.primaryText })
      Text(value === '__goal_days__'
        ? `${this.getCurrentStats().goalDays}/${this.getCurrentStats().totalDays}`
        : `${this.getCurrentStats().avgMl}ml`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
      Text(label)
        .fontSize(12)
        .fontColor(this.themeColors.textSecondary)
    }
    .layoutWeight(1)
    .padding(16)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.themeColors.card)
    .borderRadius(UiTokens.cardRadius)
  }

  private getPeriodValue(period: string): number {
    if (period === 'morning') return this.periodBreakdown.morning
    if (period === 'afternoon') return this.periodBreakdown.afternoon
    return this.periodBreakdown.evening
  }

  @Builder
  PeriodBar(label: string, period: string) {
    Column({ space: 4 }) {
      Row() {
        Text(label)
          .fontSize(13)
          .fontColor(this.themeColors.textPrimary)
        Blank()
        Text(`${this.getPeriodValue(period)}ml (${this.getPeriodPercent(this.getPeriodValue(period))}%)`)
          .fontSize(12)
          .fontColor(this.themeColors.textSecondary)
      }
      .width('100%')

      Progress({ value: this.getPeriodPercent(this.getPeriodValue(period)), total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(6)
        .color(this.themeColors.primary)
        .backgroundColor(this.themeColors.progressTrack)
        .borderRadius(3)
    }
  }
}
