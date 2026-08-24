import { router } from '@kit.ArkUI'
import { PlantService } from '../services/PlantService'
import { Plant, PlantSpecies, PLANT_SPECIES_LIST, PlantSpeciesInfo } from '../models/Plant'
import { PlantView } from '../components/PlantView'
import { GlassCard } from '../components/GlassCard'
import { PageHeader } from '../components/PageHeader'
import { getThemeColors, isSystemDarkMode, ThemeColors, UiTokens } from '../common/Theme'
import { PreferencesService } from '../services/PreferencesService'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { MIN_READABLE_FONT_SIZE_FP } from '../common/TypographyRules'
import { SystemSafeAreaBackground } from '../components/SystemSafeAreaBackground'
import { SystemBarService } from '../services/SystemBarService'
import { AppSymbol } from '../components/AppSymbol'

@Entry
@Component
struct PlantGardenPage {
  @State activePlant: Plant | null = null
  @State garden: Plant[] = []
  @State showNewPlant: boolean = false
  @State newPlantName: string = ''
  @State selectedSpecies: PlantSpecies = 'sunflower'
  @State themeColors: ThemeColors = getThemeColors(false, 'blue')
  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT

  private plantService: PlantService = new PlantService(getContext(this))
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
    this.activePlant = await this.plantService.getActivePlant()
    this.garden = await this.plantService.getGarden()
  }

  private async createPlant() {
    const speciesInfo = PLANT_SPECIES_LIST.find(s => s.species === this.selectedSpecies)
    const name = this.newPlantName.trim() || speciesInfo?.name || '我的植物'
    await this.plantService.createPlant(this.selectedSpecies, name)
    this.showNewPlant = false
    this.newPlantName = ''
    await this.refresh()
  }

  private getActiveStageIcons(): string[] {
    if (this.activePlant) {
      const info = PLANT_SPECIES_LIST.find(s => s.species === this.activePlant!.species)
      if (info) return info.stageIcons
    }
    return PLANT_SPECIES_LIST[0].stageIcons
  }

  private getNextStageText(): string {
    if (!this.activePlant) return '种一棵植物，开始你的花园之旅'
    const info = PLANT_SPECIES_LIST.find(s => s.species === this.activePlant!.species)
    const waterPerStage = info?.waterPerStage ?? 3000
    const nextStageWater = (this.activePlant.growthStage + 1) * waterPerStage
    if (this.activePlant.growthStage >= 5) return '植物已经完全成熟了！'
    const remaining = nextStageWater - this.activePlant.waterReceived
    if (remaining <= 0) return '即将进入下一阶段'
    return `再浇水 ${(remaining / 1000).toFixed(2)}L 即可进入下一阶段`
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SystemSafeAreaBackground({ colors: this.themeColors })
      Column() {
      PageHeader({
        title: '植物花园',
        textColor: this.themeColors.textPrimary,
        onBack: () => { router.back() }
      })

      Scroll() {
        Column({ space: 14 }) {
          GlassCard({ radius: UiTokens.cardRadius, cardPadding: 16, cardBackground: this.themeColors.card }) {
            Column({ space: 8 }) {
              Row() {
                Text(this.activePlant?.name ?? '植物花园')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColors.textPrimary)
                  .layoutWeight(1)
                AppSymbol({ name: PLANT_SPECIES_LIST.find(s => s.species === (this.activePlant?.species ?? 'sunflower'))?.icon ?? 'plant', symbolSize: 26, color: this.themeColors.primaryText })
              }
              .width('100%')

              if (this.activePlant) {
                Row({ space: 6 }) {
                  AppSymbol({ name: 'plant', symbolSize: 14, color: this.themeColors.textSecondary })
                  Text(`成长阶段 ${this.activePlant.growthStage + 1}/6`).fontSize(13).fontColor(this.themeColors.textSecondary)
                }

                PlantView({
                  plant: this.activePlant,
                  primaryColor: this.themeColors.primary,
                  cardColor: '#00000000',
                  textColor: this.themeColors.textPrimary,
                  textSecondary: this.themeColors.textSecondary,
                  trackColor: this.themeColors.progressTrack,
                  warningColor: this.themeColors.warning
                })
              } else {
                Text('开始记录饮水，让植物从种子发芽。')
                  .fontSize(13)
                  .fontColor(this.themeColors.textSecondary)
                  .margin({ top: 4, bottom: 8 })
              }
            }
            .width('100%')
          }

          GlassCard({ radius: UiTokens.cardRadius, cardPadding: 14, cardBackground: this.themeColors.card }) {
            Column({ space: 10 }) {
              Text('成长阶段')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.textPrimary)
                .width('100%')

              Row({ space: 8 }) {
                ForEach(this.getActiveStageIcons(), (icon: string, index: number) => {
                  Column({ space: 3 }) {
                    AppSymbol({ name: icon, symbolSize: 22, color: this.themeColors.primaryText, opacityValue: this.activePlant && index <= this.activePlant.growthStage ? 1 : 0.35 })
                    Text(['种子', '幼苗', '成长中', '开花期', '成熟期', '结果期'][index])
                      .fontSize(MIN_READABLE_FONT_SIZE_FP)
                      .fontColor(this.themeColors.textSecondary)
                  }
                  .layoutWeight(1)
                  .height(58)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                  .backgroundColor(this.activePlant && index <= this.activePlant.growthStage ? this.themeColors.positiveSurface : this.themeColors.input)
                  .borderRadius(12)
                }, (icon: string, index: number) => `${icon}-${index}`)
              }
              .width('100%')
            }
            .width('100%')
          }

          GlassCard({ radius: UiTokens.cardRadius, cardPadding: 14, cardBackground: this.themeColors.card }) {
            Row({ space: 10 }) {
              AppSymbol({ name: 'achievement', symbolSize: 22, color: this.themeColors.warning })
              Column({ space: 3 }) {
                Text(this.getNextStageText())
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.themeColors.textPrimary)
                Text('坚持记录，见证植物的成长吧！')
                  .fontSize(12)
                  .fontColor(this.themeColors.textSecondary)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
          }

          if (this.showNewPlant) {
            GlassCard({ radius: UiTokens.cardRadius, cardPadding: 16, cardBackground: this.themeColors.card }) {
              Column({ space: 12 }) {
                Text('选择植物种类')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.themeColors.textPrimary)
                  .width('100%')

                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                  ForEach(PLANT_SPECIES_LIST, (info: PlantSpeciesInfo) => {
                    Column({ space: 3 }) {
                      AppSymbol({ name: info.icon, symbolSize: 24, color: this.themeColors.primaryText })
                      Text(info.name).fontSize(12).fontColor(this.themeColors.textPrimary)
                    }
                    .width(74)
                    .height(66)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .backgroundColor(this.selectedSpecies === info.species ? this.themeColors.selectedSurface : this.themeColors.input)
                    .borderRadius(12)
                    .border({
                      width: this.selectedSpecies === info.species ? 1.5 : 0,
                      color: this.themeColors.primary
                    })
                    .margin(3)
                    .onClick(() => { this.selectedSpecies = info.species })
                  }, (info: PlantSpeciesInfo) => info.species)
                }

                TextInput({ placeholder: '给它起个名字', text: this.newPlantName })
                  .height(42)
                  .fontColor(this.themeColors.textPrimary)
                  .placeholderColor(this.themeColors.textPrimary)
                  .backgroundColor(this.themeColors.input)
                  .border({ width: 1, color: this.themeColors.divider })
                  .borderRadius(12)
                  .padding({ left: 14, right: 14 })
                  .onChange((value: string) => { this.newPlantName = value })

                Row({ space: 10 }) {
                  Button('取消')
                    .layoutWeight(1)
                    .height(48)
                    .fontColor(this.themeColors.textPrimary)
                    .backgroundColor(this.themeColors.surface)
                    .borderRadius(12)
                    .onClick(() => { this.showNewPlant = false })
                  Button('开始培育')
                    .layoutWeight(1)
                    .height(48)
                    .fontColor(this.themeColors.onPrimary)
                    .backgroundColor(this.themeColors.primary)
                    .borderRadius(12)
                    .onClick(() => { this.createPlant() })
                }
                .width('100%')
              }
              .width('100%')
            }
          } else {
            Button({ type: ButtonType.Normal }) {
              Row({ space: 8 }) {
                AppSymbol({ name: 'add', symbolSize: 18, color: this.themeColors.primaryText })
                Text('培育新植物').fontSize(15).fontColor(this.themeColors.primaryText)
              }
            }
              .width('100%')
              .height(48)
              .backgroundColor(this.themeColors.positiveSurface)
              .borderRadius(12)
              .onClick(() => { this.showNewPlant = true })
          }

          if (this.garden.length > 0) {
            GlassCard({ radius: UiTokens.cardRadius, cardPadding: 16, cardBackground: this.themeColors.card }) {
              Column({ space: 10 }) {
                Text(`我的花园 (${this.garden.length})`)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.themeColors.textPrimary)
                  .width('100%')
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.garden, (plant: Plant) => {
                    Column({ space: 3 }) {
                      AppSymbol({ name: PLANT_SPECIES_LIST.find(s => s.species === plant.species)?.icon ?? 'plant', symbolSize: 25, color: this.themeColors.primaryText })
                      Text(plant.name)
                        .fontSize(12)
                        .fontColor(this.themeColors.textSecondary)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width(70)
                    .height(64)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                  }, (plant: Plant) => plant.id)
                }
              }
              .width('100%')
            }
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
