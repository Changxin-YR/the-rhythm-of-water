import { withAlpha } from '../common/Theme'

@Component
export struct TimeRangePicker {
  @Prop startHour: number = 8
  @Prop startMinute: number = 0
  @Prop endHour: number = 22
  @Prop endMinute: number = 0
  @Prop textColor: string = '#E8F0F8'
  @Prop textSecondary: string = '#8899AA'
  @Prop primaryColor: string = '#4FC3F7'
  onStartChange?: (hour: number, minute: number) => void
  onEndChange?: (hour: number, minute: number) => void

  private formatTime(hour: number, minute: number): string {
    return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`
  }

  build() {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text('开始')
          .fontSize(12)
          .fontColor(this.textSecondary)

        Text(this.formatTime(this.startHour, this.startMinute))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(withAlpha(this.primaryColor, '15'))
          .borderRadius(10)
      }
      .alignItems(HorizontalAlign.Center)

      Text('—')
        .fontSize(20)
        .fontColor(this.textSecondary)

      Column({ space: 4 }) {
        Text('结束')
          .fontSize(12)
          .fontColor(this.textSecondary)

        Text(this.formatTime(this.endHour, this.endMinute))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(withAlpha(this.primaryColor, '15'))
          .borderRadius(10)
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(16)
  }
}
