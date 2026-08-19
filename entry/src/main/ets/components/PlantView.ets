import { Plant, PLANT_SPECIES_LIST } from '../models/Plant'
import { AppSymbol } from './AppSymbol'
import { UiTokens } from '../common/Theme'

@Component
export struct PlantView {
  @Prop plant: Plant | null = null
  @Prop primaryColor: string = '#007AFF'
  @Prop cardColor: string = '#FFFFFF'
  @Prop textColor: string = '#1D1D1F'
  @Prop textSecondary: string = '#5C5C63'
  @Prop trackColor: string = '#D1D1D6'
  @Prop warningColor: string = '#8A4B00'

  private getStageIcon(): string {
    if (!this.plant) return 'plant'
    const speciesInfo = PLANT_SPECIES_LIST.find(s => s.species === this.plant!.species)
    if (!speciesInfo) return 'plant'
    return speciesInfo.stageIcons[this.plant!.growthStage] ?? 'plant'
  }

  private getProgressPercent(): number {
    if (!this.plant) return 0
    const speciesInfo = PLANT_SPECIES_LIST.find(s => s.species === this.plant!.species)
    const waterPerStage = speciesInfo?.waterPerStage ?? 3000
    const currentStageWater = this.plant!.waterReceived % waterPerStage
    return Math.round((currentStageWater / waterPerStage) * 100)
  }

  build() {
    Column({ space: 12 }) {
      if (this.plant) {
        AppSymbol({ name: this.getStageIcon(), symbolSize: 60, color: this.primaryColor, opacityValue: this.plant!.isWilting ? 0.5 : 1.0 })

        Text(this.plant!.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)

        if (this.plant!.isWilting) {
          Text('植物有些渴了...')
            .fontSize(12)
            .fontColor(this.warningColor)
        } else {
          Text(`成长阶段 ${this.plant!.growthStage + 1}/6`)
            .fontSize(12)
            .fontColor(this.textSecondary)
        }

        Progress({ value: this.getProgressPercent(), total: 100, type: ProgressType.Linear })
          .width('80%')
          .height(6)
          .color(this.plant!.isWilting ? this.warningColor : this.primaryColor)
          .backgroundColor(this.trackColor)
          .borderRadius(3)

        Text(`累计浇水 ${Math.round(this.plant!.waterReceived / 1000 * 100) / 100}L`)
          .fontSize(12)
          .fontColor(this.textSecondary)
      } else {
        AppSymbol({ name: 'plant', symbolSize: 46, color: this.primaryColor, opacityValue: 0.4 })

        Text('还没有植物')
          .fontSize(14)
          .fontColor(this.textSecondary)

        Text('开始喝水来培养你的第一株植物吧')
          .fontSize(12)
          .fontColor(this.textSecondary)
          .opacity(0.7)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 18 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.cardColor)
    .borderRadius(UiTokens.cardRadius)
  }
}
