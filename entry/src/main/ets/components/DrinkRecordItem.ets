import { DrinkRecord } from '../models/DrinkRecord'
import { DateUtils } from '../common/DateUtils'
import { AppSymbol } from './AppSymbol'
import { UiTokens } from '../common/Theme'

@Component
export struct DrinkRecordItem {
  @Prop record: DrinkRecord
  @Prop cardColor: string = '#FFFFFF'
  @Prop textColor: string = '#1D1D1F'
  @Prop textSecondary: string = '#5C5C63'
  @Prop cardStrokeColor: string = '#C6C6C8'
  @Prop accentColor: string = '#30B0C7'
  @Prop dangerColor: string = '#D70015'
  onRecordDeleteRequest?: (record: DrinkRecord) => void
  onRecordClick?: (id: string) => void

  build() {
    Row({ space: 12 }) {
      AppSymbol({ name: this.record.beverageIcon, symbolSize: 22, color: this.accentColor })
        .width(34)

      Column({ space: 4 }) {
        Text(this.record.beverageName)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)

        Text(DateUtils.formatTime(this.record.happenedAt))
          .fontSize(12)
          .fontColor(this.textSecondary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(`${this.record.amountMl} ml`)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textColor)

    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.cardColor)
    .borderRadius(UiTokens.cardRadius)
    .onClick(() => {
      this.onRecordClick?.(this.record.id)
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          this.onRecordDeleteRequest?.(this.record)
        })
    )
  }
}
