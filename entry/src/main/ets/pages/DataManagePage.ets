import { router } from '@kit.ArkUI'
import { BackupService } from '../services/BackupService'
import { GlassCard } from '../components/GlassCard'
import { PageHeader } from '../components/PageHeader'
import { getThemeColors, isSystemDarkMode, ThemeColors, UiTokens, withAlpha } from '../common/Theme'
import { PreferencesService } from '../services/PreferencesService'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { picker } from '@kit.CoreFileKit'
import { ThemedConfirmDialog } from '../components/ThemedConfirmDialog'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'
import { SystemBarService } from '../services/SystemBarService'
import { buildBackupFileName } from '../common/BackupRules'
import { publishDataRefresh } from '../common/DataRefresh'
import { AppSymbol } from '../components/AppSymbol'

@Entry
@Component
struct DataManagePage {
  @State lastBackupPath: string = ''
  @State message: string = ''
  @State showResetDialog: boolean = false
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT

  private backupService: BackupService = new BackupService(getContext(this))
  private prefsService: PreferencesService = new PreferencesService(getContext(this))
  private systemBarService: SystemBarService = new SystemBarService()

  async aboutToAppear() {
    await this.applyTheme()
  }

  async onColorModeChange() {
    await this.applyTheme()
  }

  private async applyTheme() {
    const settings = await this.prefsService.getSettings()
    this.themeColors = getThemeColors(isSystemDarkMode(this.colorMode), settings.themeColor)
    await this.systemBarService.apply(getContext(this), this.themeColors)
  }

  private async doBackup(): Promise<void> {
    try {
      const options = new picker.DocumentSaveOptions()
      options.newFileNames = [buildBackupFileName(Date.now())]
      const targetUris = await new picker.DocumentViewPicker(getContext(this)).save(options)
      if (!targetUris || targetUris.length === 0) return

      const content = await this.backupService.exportData()
      await this.backupService.writeToFile(targetUris[0], content)
      this.lastBackupPath = targetUris[0]
      this.message = '备份成功，文件已保存'
    } catch (e) {
      this.message = '备份失败，请稍后重试'
    }
  }

  private async doRestore() {
    try {
      const documentPicker = new picker.DocumentViewPicker(getContext(this))
      const options = new picker.DocumentSelectOptions()
      options.maxSelectNumber = 1
      options.fileSuffixFilters = ['.json']
      const result = await documentPicker.select(options)
      if (!result || result.length === 0) return

      const restored = await this.backupService.importFromFile(result[0])
      this.message = restored ? '恢复成功，数据已刷新' : '恢复失败，请选择有效的备份文件'
      if (restored) publishDataRefresh()
    } catch (e) {
      this.message = '恢复失败，请稍后重试'
    }
  }

  private async doReset() {
    try {
      await this.backupService.resetAll()
      this.message = '数据已重置'
      setTimeout(() => { router.replaceUrl({ url: 'pages/OnboardingPage' }) }, 700)
    } catch (e) {
      this.message = '重置失败，请稍后重试'
    }
  }

  private showResetConfirm() {
    this.showResetDialog = true
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SystemSafeAreaBackground({ colors: this.themeColors })
      Column() {
      PageHeader({ title: '数据管理', textColor: this.themeColors.textPrimary, onBack: () => { router.back() } })

      Scroll() {
        Column({ space: 14 }) {
          GlassCard({ radius: UiTokens.cardRadius, cardPadding: 16, cardBackground: this.themeColors.card }) {
            Column({ space: 12 }) {
              Row({ space: 12 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle().width(52).height(52).fill(this.themeColors.selectedSurface)
                  AppSymbol({ name: 'upload', symbolSize: 28, color: this.themeColors.primaryText })
                }
                Column({ space: 3 }) {
                  Text('备份数据').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textPrimary)
                  Text('将所有数据导出为 JSON 文件').fontSize(12).fontColor(this.themeColors.textSecondary)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              Button('立即备份')
                .width('100%')
                .height(42)
                .fontSize(14)
                .fontColor(this.themeColors.onPrimary)
                .backgroundColor(this.themeColors.primary)
                .borderRadius(12)
                .onClick(() => { this.doBackup() })
              if (this.lastBackupPath) {
                Text('备份文件已保存')
                  .fontSize(12)
                  .fontColor(this.themeColors.textSecondary)
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
            }
            .width('100%')
          }

          GlassCard({ radius: UiTokens.cardRadius, cardPadding: 16, cardBackground: this.themeColors.card }) {
            Column({ space: 12 }) {
              Row({ space: 12 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle().width(52).height(52).fill(this.themeColors.positiveSurface)
                  AppSymbol({ name: 'download', symbolSize: 28, color: this.themeColors.success })
                }
                Column({ space: 3 }) {
                  Text('恢复备份').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textPrimary)
                  Text('从备份文件恢复饮水记录、账单和设置').fontSize(12).fontColor(this.themeColors.textSecondary)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              Button('选择文件')
                .width('100%')
                .height(42)
                .fontSize(14)
                .fontColor(this.themeColors.onPrimary)
                .backgroundColor(this.themeColors.primary)
                .borderRadius(12)
                .onClick(() => { this.doRestore() })
            }
            .width('100%')
          }

          GlassCard({ radius: UiTokens.cardRadius, cardPadding: 16, cardBackground: this.themeColors.card }) {
            Column({ space: 12 }) {
              Row({ space: 12 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle().width(52).height(52).fill(withAlpha(this.themeColors.danger, '24'))
                  AppSymbol({ name: 'trash', symbolSize: 27, color: this.themeColors.danger })
                }
                Column({ space: 3 }) {
                  Text('重置数据').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.themeColors.danger)
                  Text('清除饮水记录、账单、预算和自定义分类等本地数据').fontSize(12).fontColor(this.themeColors.textSecondary)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
                Button('重置所有数据')
                .width('100%')
                .height(42)
                .fontSize(14)
                .fontColor(this.themeColors.onPrimary)
                .backgroundColor(this.themeColors.danger)
                .borderRadius(12)
                .onClick(() => { this.showResetConfirm() })
            }
            .width('100%')
          }

          if (this.message) {
            Text(this.message)
              .fontSize(13)
              .fontColor(this.message.includes('失败') ? this.themeColors.danger : this.themeColors.success)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 4, bottom: 4 })
          }

          Row({ space: 6 }) {
            AppSymbol({ name: 'security', symbolSize: 13, color: this.themeColors.textSecondary })
            Text('数据安全有保障，仅保存在本地设备中').fontSize(12).fontColor(this.themeColors.textSecondary)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          Column().height(16)
        }
        .constraintSize({ minHeight: '100%' })
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.background)

      if (this.showResetDialog) {
        ThemedConfirmDialog({
          title: '确认重置数据？',
          message: '所有饮水记录、账单、预算、自定义分类、成就、植物和设置都会被清除，且无法恢复。',
          confirmText: '重置所有数据',
          textColor: this.themeColors.textPrimary,
          secondaryTextColor: this.themeColors.textSecondary,
          cardColor: this.themeColors.card,
          surfaceColor: this.themeColors.surface,
          dividerColor: this.themeColors.divider,
          confirmColor: this.themeColors.danger,
          onCancel: () => {
            this.showResetDialog = false
          },
          onConfirm: () => {
            this.showResetDialog = false
            this.doReset()
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
