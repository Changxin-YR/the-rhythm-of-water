import { Achievement } from '../models/Achievement'
import { AppSymbol } from './AppSymbol'
import { UiTokens } from '../common/Theme'

@Component
export struct AchievementCard {
  @Prop achievement: Achievement
  @Prop primaryColor: string = '#007AFF'
  @Prop primaryTextColor: string = '#0066CC'
  @Prop cardColor: string = '#FFFFFF'
  @Prop textColor: string = '#1D1D1F'
  @Prop textSecondary: string = '#5C5C63'
  @Prop trackColor: string = '#D1D1D6'

  build() {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(50)
          .height(50)
          .fill(this.achievement.unlockedAt ? this.primaryColor : this.trackColor)
          .opacity(this.achievement.unlockedAt ? 0.15 : 0.3)

        AppSymbol({
          name: this.achievement.icon,
          symbolSize: 22,
          color: this.primaryTextColor,
          opacityValue: this.achievement.unlockedAt ? 1.0 : 0.4
        })
      }

      Column({ space: 4 }) {
        Text(this.achievement.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)
          .opacity(this.achievement.unlockedAt ? 1.0 : 0.6)

        Text(this.achievement.description)
          .fontSize(12)
          .fontColor(this.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.achievement.unlockedAt === null) {
          Progress({ value: this.achievement.progress, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(4)
            .color(this.primaryColor)
            .backgroundColor(this.trackColor)
            .borderRadius(2)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.achievement.unlockedAt !== null) {
        Text('已达成')
          .fontSize(12)
          .fontColor(this.primaryTextColor)
          .fontWeight(FontWeight.Medium)
      } else {
        Text(`${this.achievement.progress}%`)
          .fontSize(12)
          .fontColor(this.textSecondary)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.cardColor)
    .borderRadius(UiTokens.cardRadius)
  }
}
