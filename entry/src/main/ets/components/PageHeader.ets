import { UiTokens } from '../common/Theme'
import { AppSymbol } from './AppSymbol'

@Component
export struct PageHeader {
  @Prop title: string = ''
  @Prop showBack: boolean = true
  @Prop actionText: string = ''
  @Prop textColor: string = UiTokens.textPrimary
  @Prop actionColor: string = UiTokens.primaryBlue
  @StorageProp('safeAreaTop') safeAreaTop: number = 0
  onBack?: () => void
  onAction?: () => void

  build() {
    Row({ space: 10 }) {
      if (this.showBack) {
        Button({ type: ButtonType.Normal }) {
          AppSymbol({ name: 'back', symbolSize: 22, color: this.textColor })
        }
          .width(UiTokens.headerIconButtonSize)
          .height(UiTokens.headerIconButtonSize)
          .padding(0)
          .backgroundColor(Color.Transparent)
          .borderRadius(UiTokens.headerIconButtonSize / 2)
          .onClick(() => this.onBack?.())
      }

      Text(this.title)
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .layoutWeight(1)

      if (this.actionText) {
        if (this.actionText === '+') {
          Button({ type: ButtonType.Normal }) {
            AppSymbol({ name: 'add', symbolSize: 22, color: this.actionColor })
          }
            .width(UiTokens.headerIconButtonSize)
            .height(UiTokens.headerIconButtonSize)
            .padding(0)
            .backgroundColor(Color.Transparent)
            .borderRadius(UiTokens.headerIconButtonSize / 2)
            .onClick(() => this.onAction?.())
        } else {
          Text(this.actionText)
            .fontSize(14)
            .fontColor(this.actionColor)
            .padding({ left: 8, right: 8, top: 10, bottom: 10 })
            .onClick(() => this.onAction?.())
        }
      }
    }
    .width('100%')
    .height(52)
    .margin({ top: this.safeAreaTop })
    .padding({ left: UiTokens.pageHorizontal, right: UiTokens.pageHorizontal })
    .alignItems(VerticalAlign.Center)
  }
}
