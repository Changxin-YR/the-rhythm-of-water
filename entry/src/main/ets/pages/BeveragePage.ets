import { router } from '@kit.ArkUI'
import { BeverageRepository } from '../repositories/BeverageRepository'
import { Beverage, BEVERAGE_ICON_OPTIONS } from '../models/Beverage'
import { IdGenerator } from '../common/IdGenerator'
import { getThemeColors, isSystemDarkMode, ThemeColors, UiTokens } from '../common/Theme'
import { PreferencesService } from '../services/PreferencesService'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { GlassCard } from '../components/GlassCard'
import { PageHeader } from '../components/PageHeader'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'
import { SystemBarService } from '../services/SystemBarService'
import { publishDataRefresh } from '../common/DataRefresh'
import { AppSymbol } from '../components/AppSymbol'

@Entry
@Component
struct BeveragePage {
  @State beverages: Beverage[] = []
  @State showAddForm: boolean = false
  @State newName: string = ''
  @State newIcon: string = BEVERAGE_ICON_OPTIONS[0]
  @State newRate: number = 80
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT

  private repo: BeverageRepository = new BeverageRepository(getContext(this))
  private prefsService: PreferencesService = new PreferencesService(getContext(this))
  private systemBarService: SystemBarService = new SystemBarService()

  async aboutToAppear() {
    await this.applyTheme()
    await this.refresh()
  }

  async onColorModeChange() {
    await this.applyTheme()
  }

  async onPageShow() {
    await this.refresh()
  }

  private async applyTheme() {
    const settings = await this.prefsService.getSettings()
    this.themeColors = getThemeColors(isSystemDarkMode(this.colorMode), settings.themeColor)
    await this.systemBarService.apply(getContext(this), this.themeColors)
  }

  private async refresh() {
    this.beverages = await this.repo.list()
  }

  private async addBeverage() {
    if (!this.newName.trim()) return
    const beverage: Beverage = {
      id: IdGenerator.generate(),
      name: this.newName.trim(),
      icon: this.newIcon,
      hydrationRate: this.newRate / 100,
      caffeinePerMl: 0,
      isCustom: true,
      isActive: true
    }
    await this.repo.save(beverage)
    this.newName = ''
    this.newRate = 80
    this.showAddForm = false
    await this.refresh()
    publishDataRefresh()
  }

  private async toggleActive(beverage: Beverage) {
    beverage.isActive = !beverage.isActive
    await this.repo.save(beverage)
    await this.refresh()
    publishDataRefresh()
  }

  private async deleteBeverage(id: string) {
    await this.repo.remove(id)
    await this.refresh()
    publishDataRefresh()
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SystemSafeAreaBackground({ colors: this.themeColors })
      Column() {
      PageHeader({
        title: '饮品管理',
        actionText: '+',
        textColor: this.themeColors.textPrimary,
        actionColor: this.themeColors.primary,
        onBack: () => { router.back() },
        onAction: () => { this.showAddForm = !this.showAddForm }
      })

      Scroll() {
        Column({ space: 14 }) {
          if (this.showAddForm) {
            GlassCard({ radius: UiTokens.cardRadius, cardPadding: 16, cardBackground: this.themeColors.card }) {
              Column({ space: 12 }) {
                Row({ space: 8 }) {
                  AppSymbol({ name: 'water', symbolSize: 22, color: this.themeColors.primaryText })
                  Text('添加新饮品').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textPrimary)
                }
                .width('100%')

                TextInput({ placeholder: '饮品名称', text: this.newName })
                  .height(42)
                  .fontColor(this.themeColors.textPrimary)
                  .placeholderColor(this.themeColors.textPrimary)
                  .backgroundColor(this.themeColors.input)
                  .border({ width: 1, color: this.themeColors.divider })
                  .borderRadius(12)
                  .padding({ left: 14, right: 14 })
                  .onChange((value: string) => { this.newName = value })

                Row({ space: 6 }) {
                  ForEach(BEVERAGE_ICON_OPTIONS, (icon: string) => {
                    AppSymbol({ name: icon, symbolSize: 22, color: this.themeColors.primaryText })
                      .width(UiTokens.minimumTouchTargetSize)
                      .height(UiTokens.minimumTouchTargetSize)
                      .backgroundColor(this.newIcon === icon ? this.themeColors.selectedSurface : this.themeColors.input)
                      .borderRadius(10)
                      .onClick(() => { this.newIcon = icon })
                  }, (icon: string) => icon)
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)

                Row() {
                  Text(`水合比例 ${this.newRate}%`)
                    .fontSize(13)
                    .fontColor(this.themeColors.textSecondary)
                    .layoutWeight(1)
                  Text('100%').fontSize(12).fontColor(this.themeColors.textSecondary)
                }
                .width('100%')
                Slider({ value: this.newRate, min: 0, max: 100, step: 5 })
                  .width('100%')
                  .selectedColor(this.themeColors.primary)
                  .onChange((value: number) => { this.newRate = Math.round(value) })

                Button('添加饮品')
                  .width('100%')
                  .height(UiTokens.buttonHeight)
                  .fontSize(16)
                  .fontColor(this.themeColors.onPrimary)
                  .backgroundColor(this.themeColors.primary)
                  .borderRadius(12)
                  .onClick(() => { this.addBeverage() })
              }
              .width('100%')
            }
          }

          GlassCard({ radius: UiTokens.cardRadius, cardPadding: 4, cardBackground: this.themeColors.card }) {
            Column() {
              ForEach(this.beverages, (item: Beverage, index: number) => {
                Row({ space: 12 }) {
                  AppSymbol({ name: item.icon, symbolSize: 24, color: this.themeColors.primaryText }).width(34)
                  Column({ space: 3 }) {
                    Text(item.name).fontSize(15).fontColor(this.themeColors.textPrimary)
                    Text(`水合 ${Math.round(item.hydrationRate * 100)}%`)
                      .fontSize(12)
                      .fontColor(this.themeColors.textSecondary)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  Toggle({ type: ToggleType.Switch, isOn: item.isActive })
                    .selectedColor(this.themeColors.primary)
                    .onChange(() => { this.toggleActive(item) })
                  if (item.isCustom) {
                    Text('×')
                      .fontSize(18)
                      .fontColor(this.themeColors.danger)
                      .width(UiTokens.minimumTouchTargetSize)
                      .height(UiTokens.minimumTouchTargetSize)
                      .textAlign(TextAlign.Center)
                      .onClick(() => { this.deleteBeverage(item.id) })
                  }
                }
                .width('100%')
                .height(58)
                .padding({ left: 12, right: 12 })
                if (index < this.beverages.length - 1) Divider().color(this.themeColors.divider).strokeWidth(1)
              }, (item: Beverage) => item.id)
            }
            .width('100%')
          }
          Column().height(20)
        }
        .constraintSize({ minHeight: '100%' })
        .justifyContent(FlexAlign.Start)
        .padding({ left: 20, right: 20, bottom: 20 })
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
