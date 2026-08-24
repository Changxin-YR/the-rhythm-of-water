import { DrinkService } from '../services/DrinkService'
import { GoalService } from '../services/GoalService'
import { PlantService } from '../services/PlantService'
import { AchievementService } from '../services/AchievementService'
import { PreferencesService } from '../services/PreferencesService'
import { BeverageRepository } from '../repositories/BeverageRepository'
import { DrinkRecord, DrinkRecordPayload } from '../models/DrinkRecord'
import { Beverage } from '../models/Beverage'
import { DailySummary } from '../models/DailySummary'
import { Constants } from '../common/Constants'
import { DateUtils } from '../common/DateUtils'
import { getThemeColors, isSystemDarkMode, ThemeColors } from '../common/Theme'
import { UiTokens } from '../common/Theme'
import { completionPercent, remainingGoalMl } from '../common/DashboardData'
import { resolveSelectedId } from '../common/WaterReminderRules'
import { publishDataRefresh } from '../common/DataRefresh'
import { WaterWaveProgress } from '../components/WaterWaveProgress'
import { QuickAddButton } from '../components/QuickAddButton'
import { DrinkRecordItem } from '../components/DrinkRecordItem'
import { BeverageSelector } from '../components/BeverageSelector'
import { AmountInputDialog } from '../components/AmountInputDialog'
import { ThemedConfirmDialog } from '../components/ThemedConfirmDialog'
import { AppSymbol } from '../components/AppSymbol'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { vibrator } from '@kit.SensorServiceKit'
import { promptAction, router } from '@kit.ArkUI'

@Component
export struct HomePage {
  @State summary: DailySummary = {
    date: DateUtils.getToday(),
    totalMl: 0,
    hydrationMl: 0,
    goalMl: 2000,
    completionRate: 0,
    recordCount: 0,
    beverageBreakdown: {},
    streakDay: 0
  }
  @State todayRecords: DrinkRecord[] = []
  @State beverages: Beverage[] = []
  @State selectedBeverage: Beverage | null = null
  @State showBeverageSelector: boolean = false
  @State showAmountDialog: boolean = false
  @State showRecordDeleteDialog: boolean = false
  @State pendingDeleteRecordId: string = ''
  @State pendingDeleteMessage: string = ''
  @State showUndoBar: boolean = false
  @State undoRecord: DrinkRecord | null = null
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @StorageProp('refreshSignal') @Watch('onRefreshSignal') refreshSignal: number = 0

  private drinkService: DrinkService = new DrinkService(getContext(this))
  private goalService: GoalService = new GoalService(getContext(this))
  private plantService: PlantService = new PlantService(getContext(this))
  private achievementService: AchievementService = new AchievementService(getContext(this))
  private prefsService: PreferencesService = new PreferencesService(getContext(this))
  private beverageRepo: BeverageRepository = new BeverageRepository(getContext(this))
  private undoTimerId: number = -1

  async aboutToAppear() {
    await this.loadTheme()
    await this.refresh()
  }

  aboutToDisappear() {
    if (this.undoTimerId !== -1) {
      clearTimeout(this.undoTimerId)
      this.undoTimerId = -1
    }
  }

  async onRefreshSignal() {
    await this.loadTheme()
    await this.refresh()
  }

  async onColorModeChange() {
    await this.loadTheme()
  }

  async onPageShow() {
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
    this.summary = await this.drinkService.getTodaySummary(goalMl)
    this.summary.streakDay = await this.drinkService.getStreak(goalMl)
    this.todayRecords = await this.drinkService.getTodayRecords()
    this.beverages = await this.beverageRepo.getActive()
    const selectedId = resolveSelectedId(
      this.selectedBeverage?.id ?? null,
      this.beverages.map((beverage: Beverage) => beverage.id)
    )
    this.selectedBeverage = selectedId === null
      ? null
      : this.beverages.find((beverage: Beverage) => beverage.id === selectedId) ?? null
  }

  private async addDrink(amountMl: number) {
    const bev = this.selectedBeverage ?? this.beverages[0]
    if (!bev) {
      promptAction.showToast({ message: '请先启用至少一种饮品' })
      return
    }

    const payload: DrinkRecordPayload = {
      beverageId: bev.id,
      beverageName: bev.name,
      beverageIcon: bev.icon,
      amountMl: amountMl,
      hydrationRate: bev.hydrationRate,
      happenedAt: Date.now()
    }

    const record = await this.drinkService.addRecord(payload)
    await this.plantService.waterPlant(record.hydrationMl)
    await this.achievementService.checkAndUpdate(this.summary.goalMl)

    try {
      vibrator.startVibration({ type: 'time', duration: 50 }, { id: 0, usage: 'touch' })
    } catch (e) {
      console.warn('HomePage: vibration feedback unavailable', JSON.stringify(e))
    }

    this.undoRecord = record
    this.showUndoBar = true
    if (this.undoTimerId !== -1) clearTimeout(this.undoTimerId)
    this.undoTimerId = setTimeout(() => {
      this.showUndoBar = false
      this.undoRecord = null
    }, Constants.SNACKBAR_DURATION)

    await this.refresh()
    publishDataRefresh()

  }

  private async undoLastRecord() {
    if (!this.undoRecord) return
    const record = this.undoRecord
    await this.drinkService.removeRecord(record.id)
    await this.reconcileAfterRecordRemoval(record)
    this.showUndoBar = false
    this.undoRecord = null
    await this.refresh()
    publishDataRefresh()
  }

  private async deleteRecord(id: string) {
    const record = await this.drinkService.getRecord(id)
    if (!record) return
    await this.drinkService.removeRecord(id)
    await this.reconcileAfterRecordRemoval(record)
    await this.refresh()
    publishDataRefresh()
  }

  private async reconcileAfterRecordRemoval(record: DrinkRecord): Promise<void> {
    await this.plantService.removeWater(record.hydrationMl)
    const goalMl = await this.goalService.getGoal()
    await this.achievementService.checkAndUpdate(goalMl)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Row() {
          Column({ space: 2 }) {
            Text(`${DateUtils.getToday()}`)
              .fontSize(13)
              .fontColor(this.themeColors.textSecondary)
            Text(`今日 · ${DateUtils.getWeekdayToday()}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
          }
          .alignItems(HorizontalAlign.Start)

        }
        .width('100%')
        .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal, top: 14, bottom: 8 })

        Scroll() {
          Column({ space: 20 }) {
            Column({ space: 12 }) {
              WaterWaveProgress({
                progress: completionPercent(this.summary.hydrationMl, this.summary.goalMl),
                currentMl: this.summary.hydrationMl,
                goalMl: this.summary.goalMl,
                primaryColor: this.themeColors.primary,
                primaryTextColor: this.themeColors.primaryText,
                secondaryColor: this.themeColors.secondary,
                textColor: this.themeColors.textPrimary,
                trackColor: this.themeColors.progressTrack
              })

              if (this.summary.completionRate >= 100) {
                Text('今日目标已达成')
                  .fontSize(15)
                  .fontColor(this.themeColors.success)
                  .fontWeight(FontWeight.Medium)
              } else {
                Text(`还需喝 ${remainingGoalMl(this.summary.hydrationMl, this.summary.goalMl)} ml 即可达标`)
                  .fontSize(14)
                  .fontColor(this.themeColors.textSecondary)
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 8, bottom: 2 })

            Text('快速添加')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textPrimary)
              .width('100%')

            Row({ space: 12 }) {
              ForEach(Constants.QUICK_ADD_AMOUNTS, (amount: number) => {
                QuickAddButton({
                  amount: amount,
                  icon: this.selectedBeverage?.icon ?? 'water',
                  primaryColor: this.themeColors.primary,
                  cardColor: this.themeColors.card,
                  textColor: this.themeColors.textPrimary,
                  onQuickAdd: () => { this.addDrink(amount) },
                  onLongPress: () => { this.showBeverageSelector = true }
                })
              }, (amount: number) => amount.toString())
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)

            Button({ type: ButtonType.Normal }) {
              Row({ space: 8 }) {
                AppSymbol({ name: 'add', symbolSize: 18, color: this.themeColors.primaryText })
                Text('自定义').fontSize(15).fontColor(this.themeColors.primaryText)
              }
            }
              .backgroundColor(this.themeColors.positiveSurface)
              .borderRadius(12)
              .height(UiTokens.buttonHeight)
              .width(180)
              .onClick(() => {
                this.showAmountDialog = true
              })

            // Beverage quick switch
            if (this.selectedBeverage) {
              Row({ space: 6 }) {
                AppSymbol({ name: this.selectedBeverage.icon, symbolSize: 16, color: this.themeColors.primaryText })
                Text('当前饮品：')
                  .fontSize(12)
                  .fontColor(this.themeColors.textSecondary)
                Text(this.selectedBeverage.name)
                  .fontSize(12)
                  .fontColor(this.themeColors.primaryText)
                Text('切换')
                  .fontSize(12)
                  .fontColor(this.themeColors.primaryText)
                  .decoration({ type: TextDecorationType.Underline })
                  .onClick(() => {
                    this.showBeverageSelector = true
                  })
              }
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor(this.themeColors.card)
              .borderRadius(12)
            }

            Column({ space: 8 }) {
              Row() {
                Text('今日记录')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.themeColors.textPrimary)
                Blank()
                Text(`${this.todayRecords.length}杯`)
                  .fontSize(13)
                  .fontColor(this.themeColors.textSecondary)
              }
              .width('100%')

              if (this.todayRecords.length === 0) {
                Column({ space: 8 }) {
                  AppSymbol({ name: 'water', symbolSize: 36, color: this.themeColors.primaryText, opacityValue: 0.4 })
                  Text('还没有记录，开始喝水吧')
                    .fontSize(14)
                    .fontColor(this.themeColors.textSecondary)
                }
                .width('100%')
                .padding(32)
                .alignItems(HorizontalAlign.Center)
              } else {
                ForEach(this.todayRecords, (record: DrinkRecord) => {
                  DrinkRecordItem({
                    record: record,
                    cardColor: this.themeColors.card,
                    textColor: this.themeColors.textPrimary,
                    textSecondary: this.themeColors.textSecondary,
                    cardStrokeColor: this.themeColors.divider,
                    accentColor: this.themeColors.accent,
                    dangerColor: this.themeColors.danger,
                    onRecordDeleteRequest: (record: DrinkRecord) => {
                      this.pendingDeleteRecordId = record.id
                      this.pendingDeleteMessage = `确定要删除 ${record.amountMl}ml ${record.beverageName} 的记录吗？`
                      this.showRecordDeleteDialog = true
                    },
                    onRecordClick: (id: string) => {
                      router.pushUrl({ url: 'pages/RecordDetailPage', params: { id: id } })
                    }
                  })
                }, (record: DrinkRecord) => record.id)
              }
            }
            .width('100%')
            .padding({ top: 2 })

            Column().height(92)
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

      if (this.showUndoBar && this.undoRecord) {
        Row({ space: 8 }) {
          Text(`已记录 ${this.undoRecord.amountMl}ml ${this.undoRecord.beverageName}`)
            .fontSize(14)
            .fontColor(this.themeColors.textPrimary)
            .layoutWeight(1)

          Button('撤销')
            .fontSize(13)
            .fontColor(this.themeColors.primaryText)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.undoLastRecord()
            })
        }
        .width('90%')
        .padding({ left: 16, right: 8, top: 12, bottom: 12 })
        .backgroundColor(this.themeColors.surface)
        .borderRadius(18)
        .margin({ bottom: 16 })
        .zIndex(1)
        .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 20 } })
      }

      if (this.showBeverageSelector) {
        Column() {
          Column()
            .width('100%')
            .layoutWeight(1)
            .backgroundColor(this.themeColors.dialogOverlay)
            .onClick(() => { this.showBeverageSelector = false })

          Column() {
            BeverageSelector({
              beverages: this.beverages,
              selectedId: this.selectedBeverage?.id ?? 'water',
              primaryColor: this.themeColors.primary,
              cardColor: this.themeColors.card,
              textColor: this.themeColors.textPrimary,
              dividerColor: this.themeColors.divider,
              onSelect: (bev: Beverage) => {
                this.selectedBeverage = bev
                this.showBeverageSelector = false
              }
            })
          }
          .width('100%')
          .backgroundColor(this.themeColors.card)
          .borderRadius({ topLeft: 20, topRight: 20 })
          .padding({ bottom: 20 })
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
      }

      if (this.showAmountDialog) {
        AmountInputDialog({
          primaryColor: this.themeColors.primary,
          onPrimaryColor: this.themeColors.onPrimary,
          textColor: this.themeColors.textPrimary,
          cardColor: this.themeColors.card,
          surfaceColor: this.themeColors.input,
          dangerColor: this.themeColors.danger,
          onCancel: () => {
            this.showAmountDialog = false
          },
          onConfirm: (amount: number) => {
            this.showAmountDialog = false
            this.addDrink(amount)
          }
        })
      }

      if (this.showRecordDeleteDialog) {
        ThemedConfirmDialog({
          title: '删除记录',
          message: this.pendingDeleteMessage,
          confirmText: '删除',
          textColor: this.themeColors.textPrimary,
          secondaryTextColor: this.themeColors.textSecondary,
          cardColor: this.themeColors.card,
          surfaceColor: this.themeColors.surface,
          dividerColor: this.themeColors.divider,
          confirmColor: this.themeColors.danger,
          onCancel: () => {
            this.showRecordDeleteDialog = false
            this.pendingDeleteRecordId = ''
            this.pendingDeleteMessage = ''
          },
          onConfirm: () => {
            const id = this.pendingDeleteRecordId
            this.showRecordDeleteDialog = false
            this.pendingDeleteRecordId = ''
            this.pendingDeleteMessage = ''
            this.deleteRecord(id)
          }
        })
      }
    }
  }
}
