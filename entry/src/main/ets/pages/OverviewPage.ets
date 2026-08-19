import { ConfigurationConstant } from '@kit.AbilityKit'
import { DrinkService } from '../services/DrinkService'
import { GoalService } from '../services/GoalService'
import { PreferencesService } from '../services/PreferencesService'
import { StatisticsService } from '../ledger/services/StatisticsService'
import { DailySummary } from '../models/DailySummary'
import { MonthSummary } from '../ledger/models/Statistics'
import { DateUtils } from '../common/DateUtils'
import { completionPercent, formatBalance } from '../common/OverviewData'
import { getThemeColors, isSystemDarkMode, ThemeColors, UiTokens } from '../common/Theme'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'
import { AppSymbol } from '../components/AppSymbol'

export interface OverviewPageOptions {
  onOpenWater: () => void
  onOpenLedger: () => void
  onOpenSettings: () => void
}

@Component
export struct OverviewPage {
  @Prop options: OverviewPageOptions
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @State waterSummary: DailySummary = {
    date: DateUtils.getToday(), totalMl: 0, hydrationMl: 0, goalMl: 2000,
    completionRate: 0, recordCount: 0, beverageBreakdown: {}, streakDay: 0
  }
  @State monthSummary: MonthSummary = {
    year: new Date().getFullYear(), month: new Date().getMonth() + 1,
    totalIncome: 0, totalExpense: 0, balance: 0, billCount: 0
  }
  @State waterLoadFailed: boolean = false
  @State ledgerLoadFailed: boolean = false
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @StorageProp('refreshSignal') @Watch('onRefreshSignal') refreshSignal: number = 0

  private drinkService: DrinkService = new DrinkService(getContext(this))
  private goalService: GoalService = new GoalService(getContext(this))
  private prefsService: PreferencesService = new PreferencesService(getContext(this))
  private statisticsService: StatisticsService = new StatisticsService()

  async aboutToAppear() {
    await this.reloadTheme()
    await this.refresh()
  }

  async onColorModeChange() {
    await this.reloadTheme()
  }

  async onRefreshSignal() {
    await this.reloadTheme()
    await this.refresh()
  }

  private async reloadTheme() {
    const settings = await this.prefsService.getSettings()
    this.themeColors = getThemeColors(isSystemDarkMode(this.colorMode), settings.themeColor)
  }

  private async refresh() {
    this.waterLoadFailed = false
    this.ledgerLoadFailed = false
    try {
      const goal = await this.goalService.getGoal()
      this.waterSummary = await this.drinkService.getTodaySummary(goal)
      this.waterSummary.streakDay = await this.drinkService.getStreak(goal)
    } catch (error) {
      this.waterLoadFailed = true
      console.error('OverviewPage: water summary failed', JSON.stringify(error))
    }
    try {
      this.monthSummary = await this.statisticsService.getMonthSummary(new Date().getFullYear(), new Date().getMonth() + 1)
    } catch (error) {
      this.ledgerLoadFailed = true
      console.error('OverviewPage: ledger summary failed', JSON.stringify(error))
    }
  }

  private goWater() {
    this.options.onOpenWater()
  }

  private goLedger() {
    this.options.onOpenLedger()
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SystemSafeAreaBackground({ colors: this.themeColors })
      Column() {
        Row() {
          Column({ space: 3 }) {
            Text('元气有数')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
            Text(`${DateUtils.getToday()} · ${DateUtils.getWeekdayToday()}`)
              .fontSize(13)
              .fontColor(this.themeColors.textSecondary)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button({ type: ButtonType.Normal }) {
            AppSymbol({ name: 'settings', symbolSize: 22, color: this.themeColors.primaryText })
          }
            .width(UiTokens.recommendedTouchTargetSize)
            .height(UiTokens.recommendedTouchTargetSize)
            .padding(0)
            .backgroundColor(Color.Transparent)
            .onClick(() => { this.options.onOpenSettings() })
        }
        .width('100%')
        .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal, top: 16, bottom: 12 })

        Scroll() {
          Column({ space: 14 }) {
            Column({ space: 10 }) {
              Row() {
                Text('今日饮水')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColors.textPrimary)
                Blank()
                Text(this.waterLoadFailed ? '暂不可用' : `${completionPercent(this.waterSummary.hydrationMl, this.waterSummary.goalMl)}%`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColors.primaryText)
              }
              .width('100%')

              Text(this.waterLoadFailed
                ? '饮水数据暂时无法读取，请稍后重试'
                : `${this.waterSummary.hydrationMl} / ${this.waterSummary.goalMl} ml`)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.textPrimary)

              Progress({ value: completionPercent(this.waterSummary.hydrationMl, this.waterSummary.goalMl), total: 100, type: ProgressType.Linear })
                .width('100%')
                .height(10)
                .color(this.themeColors.primary)
                .backgroundColor(this.themeColors.progressTrack)

              Text(this.waterLoadFailed ? '刷新后会自动恢复' : `连续达标 ${this.waterSummary.streakDay} 天`)
                .fontSize(13)
                .fontColor(this.themeColors.textSecondary)
            }
            .width('100%')
            .padding(18)
            .backgroundColor(this.themeColors.card)
            .borderRadius(UiTokens.cardRadius)
            .onClick(() => { this.goWater() })

            Column({ space: 10 }) {
              Row() {
                Text('本月收支')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColors.textPrimary)
                Blank()
                Text(this.ledgerLoadFailed ? '暂不可用' : formatBalance(this.monthSummary.balance))
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.monthSummary.balance >= 0 ? this.themeColors.success : this.themeColors.danger)
              }
              .width('100%')

              Row({ space: 10 }) {
                Column() {
                  Text(`收入 ${formatBalance(this.monthSummary.totalIncome)}`)
                    .fontSize(14)
                    .fontColor(this.themeColors.success)
                }
                .layoutWeight(1)
                Column() {
                  Text(`支出 ${formatBalance(this.monthSummary.totalExpense)}`)
                    .fontSize(14)
                    .fontColor(this.themeColors.danger)
                }
                .layoutWeight(1)
              }
              .width('100%')
              Text(this.ledgerLoadFailed ? '账本数据暂时无法读取，请稍后重试' : `本月 ${this.monthSummary.billCount} 笔记录`)
                .fontSize(13)
                .fontColor(this.themeColors.textSecondary)
            }
            .width('100%')
            .padding(18)
            .backgroundColor(this.themeColors.card)
            .borderRadius(UiTokens.cardRadius)
            .onClick(() => { this.goLedger() })

            Text('快捷操作')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
              .width('100%')

            Row({ space: 12 }) {
              Button({ type: ButtonType.Normal }) {
                Row({ space: 8 }) {
                  AppSymbol({ name: 'water', symbolSize: 18, color: this.themeColors.primaryText })
                  Text('记录饮水').fontSize(15).fontColor(this.themeColors.primaryText)
                }
              }
                .layoutWeight(1)
                .height(48)
                .backgroundColor(this.themeColors.selectedSurface)
                .borderRadius(12)
                .onClick(() => { this.goWater() })
              Button({ type: ButtonType.Normal }) {
                Row({ space: 8 }) {
                  AppSymbol({ name: 'add', symbolSize: 18, color: this.themeColors.primaryText })
                  Text('记一笔').fontSize(15).fontColor(this.themeColors.primaryText)
                }
              }
                .layoutWeight(1)
                .height(48)
                .backgroundColor(this.themeColors.positiveSurface)
                .borderRadius(12)
                .onClick(() => { this.goLedger() })
            }
            .width('100%')

            Column({ space: 8 }) {
              Text('最近活动')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.textPrimary)
              Text(this.waterSummary.recordCount === 0 && this.monthSummary.billCount === 0
                ? '还没有活动，先记录今天的第一杯水或第一笔账吧。'
                : `今日饮水 ${this.waterSummary.recordCount} 次 · 本月记账 ${this.monthSummary.billCount} 笔`)
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
            }
            .width('100%')
            .padding(18)
            .backgroundColor(this.themeColors.card)
            .borderRadius(UiTokens.cardRadius)

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
      .backgroundColor(this.themeColors.background)
    }
    .width('100%')
    .height('100%')
  }
}
