import { router } from '@kit.ArkUI'
import { DrinkService } from '../services/DrinkService'
import { DrinkRecord } from '../models/DrinkRecord'
import { DateUtils } from '../common/DateUtils'
import { getThemeColors, isSystemDarkMode, ThemeColors } from '../common/Theme'
import { PreferencesService } from '../services/PreferencesService'
import { PlantService } from '../services/PlantService'
import { AchievementService } from '../services/AchievementService'
import { GoalService } from '../services/GoalService'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { GlassCard } from '../components/GlassCard'
import { PageHeader } from '../components/PageHeader'
import { publishDataRefresh } from '../common/DataRefresh'
import { ThemedConfirmDialog } from '../components/ThemedConfirmDialog'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'
import { SystemBarService } from '../services/SystemBarService'
import { AppSymbol } from '../components/AppSymbol'
import { UiTokens } from '../common/Theme'

@Entry
@Component
struct RecordDetailPage {
  @State record: DrinkRecord | null = null
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT

  private drinkService: DrinkService = new DrinkService(getContext(this))
  private prefsService: PreferencesService = new PreferencesService(getContext(this))
  private plantService: PlantService = new PlantService(getContext(this))
  private achievementService: AchievementService = new AchievementService(getContext(this))
  private goalService: GoalService = new GoalService(getContext(this))
  private systemBarService: SystemBarService = new SystemBarService()
  @State showDeleteDialog: boolean = false

  async aboutToAppear() {
    await this.applyTheme()
    const params = router.getParams() as Record<string, string>
    if (params && params['id']) this.record = await this.drinkService.getRecord(params['id'])
  }

  private confirmDelete() {
    this.showDeleteDialog = true
  }

  async onColorModeChange() {
    await this.applyTheme()
  }

  private async applyTheme() {
    const settings = await this.prefsService.getSettings()
    this.themeColors = getThemeColors(isSystemDarkMode(this.colorMode), settings.themeColor)
    await this.systemBarService.apply(getContext(this), this.themeColors)
  }

  private async deleteAndBack() {
    if (this.record) {
      await this.drinkService.removeRecord(this.record.id)
      await this.plantService.removeWater(this.record.hydrationMl)
      await this.achievementService.checkAndUpdate(await this.goalService.getGoal())
      publishDataRefresh()
    }
    router.back()
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      SystemSafeAreaBackground({ colors: this.themeColors })
      Column() {
      PageHeader({
        title: '记录详情',
        actionText: '删除',
        textColor: this.themeColors.textPrimary,
        actionColor: this.themeColors.danger,
        onBack: () => { router.back() },
        onAction: () => { this.confirmDelete() }
      })

      Scroll() {
        if (this.record) {
          Column({ space: 14 }) {
            GlassCard({ radius: UiTokens.cardRadius, cardPadding: 22, cardBackground: this.themeColors.card }) {
              Column({ space: 9 }) {
                AppSymbol({ name: this.record!.beverageIcon, symbolSize: 48, color: this.themeColors.primaryText })
                Text(this.record!.beverageName)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColors.textPrimary)
                Text('已记录一杯饮品')
                  .fontSize(12)
                  .fontColor(this.themeColors.textSecondary)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }

            GlassCard({ radius: UiTokens.cardRadius, cardPadding: 18, cardBackground: this.themeColors.card }) {
              Column({ space: 0 }) {
                this.DetailRow('饮用量', `${this.record!.amountMl} ml`)
                Divider().color(this.themeColors.divider).strokeWidth(1)
                this.DetailRow('有效水合', `${this.record!.hydrationMl} ml`)
                Divider().color(this.themeColors.divider).strokeWidth(1)
                this.DetailRow('饮用时间', DateUtils.formatDateTime(this.record!.happenedAt))
                Divider().color(this.themeColors.divider).strokeWidth(1)
                this.DetailRow('记录时间', DateUtils.formatDateTime(this.record!.createdAt))
              }
              .width('100%')
            }

            Text('删除后，首页、统计、成就和植物状态都会同步更新。')
              .fontSize(12)
              .fontColor(this.themeColors.textSecondary)
              .width('100%')
              .textAlign(TextAlign.Center)
          }
          .constraintSize({ minHeight: '100%' })
          .justifyContent(FlexAlign.Start)
          .padding({ left: 20, right: 20, top: 12, bottom: 20 })
        } else {
          Column() {
            Text('记录不存在').fontSize(16).fontColor(this.themeColors.textSecondary)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.background)

      if (this.showDeleteDialog) {
        ThemedConfirmDialog({
          title: '删除这条记录？',
          message: '删除后会同步回退今日进度和植物浇水量。',
          confirmText: '删除',
          textColor: this.themeColors.textPrimary,
          secondaryTextColor: this.themeColors.textSecondary,
          cardColor: this.themeColors.card,
          surfaceColor: this.themeColors.surface,
          dividerColor: this.themeColors.divider,
          confirmColor: this.themeColors.danger,
          onCancel: () => {
            this.showDeleteDialog = false
          },
          onConfirm: () => {
            this.showDeleteDialog = false
            this.deleteAndBack()
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DetailRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor(this.themeColors.textSecondary)
      Blank()
      Text(value)
        .fontSize(14)
        .fontColor(this.themeColors.textPrimary)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(48)
  }
}
