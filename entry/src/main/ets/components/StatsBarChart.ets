import { DailySummary } from '../models/DailySummary'

@Component
export struct StatsBarChart {
  @Prop data: DailySummary[] = []
  @Prop goalMl: number = 2000
  @Prop primaryColor: string = '#4FC3F7'
  @Prop secondaryColor: string = '#81D4FA'
  @Prop textColor: string = '#E8F0F8'
  @Prop textSecondary: string = '#8899AA'
  @Prop labels: string[] = []

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        ForEach(this.data, (item: DailySummary, index: number) => {
          Column({ space: 4 }) {
            // Bar
            Column() {
              Column()
                .width('100%')
                .height(`${Math.min(100, (item.hydrationMl / this.goalMl) * 100)}%`)
                .backgroundColor(item.completionRate >= 100 ? this.primaryColor : this.secondaryColor)
                .borderRadius(4)
            }
            .width(18)
            .height(118)
            .justifyContent(FlexAlign.End)

            // Label
            Text(this.labels[index] ?? '')
              .fontSize(12)
              .fontColor(this.textSecondary)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }, (item: DailySummary) => item.date)
      }
      .width('100%')

      // Goal line indicator
      Row({ space: 4 }) {
        Divider()
          .strokeWidth(1)
          .color(this.primaryColor)
          .opacity(0.5)
          .layoutWeight(1)

        Text(`目标 ${this.goalMl}ml`)
          .fontSize(12)
          .fontColor(this.textSecondary)
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 8 })
  }
}
