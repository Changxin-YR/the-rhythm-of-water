import { DailySummary } from '../models/DailySummary'

import { withAlpha } from '../common/Theme'

@Component
export struct HeatmapCalendar {
  @Prop data: DailySummary[] = []
  @Prop primaryColor: string = '#4FC3F7'
  @Prop cardColor: string = '#1B2838'
  @Prop textColor: string = '#E8F0F8'
  @Prop textSecondary: string = '#8899AA'
  @Prop trackColor: string = '#425466'

  private getColorForRate(rate: number): string {
    if (rate >= 100) return this.primaryColor
    if (rate >= 75) return withAlpha(this.primaryColor, 'C0')
    if (rate >= 50) return withAlpha(this.primaryColor, '80')
    if (rate >= 25) return withAlpha(this.primaryColor, '40')
    return this.trackColor
  }

  build() {
    Column({ space: 8 }) {
      // Legend
      Row({ space: 8 }) {
        Text('少')
          .fontSize(12)
          .fontColor(this.textSecondary)
        Row({ space: 2 }) {
          ForEach([0, 25, 50, 75, 100], (rate: number) => {
            Column()
              .width(12)
              .height(12)
              .borderRadius(3)
              .backgroundColor(this.getColorForRate(rate))
          }, (rate: number) => rate.toString())
        }
        Text('多')
          .fontSize(12)
          .fontColor(this.textSecondary)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)

      // Calendar grid
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.data, (item: DailySummary) => {
          Column()
            .width(14)
            .height(14)
            .borderRadius(3)
            .backgroundColor(this.getColorForRate(item.completionRate))
            .margin(1)
        }, (item: DailySummary) => item.date)
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
  }
}
