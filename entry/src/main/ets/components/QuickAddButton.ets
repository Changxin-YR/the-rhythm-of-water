import { AppSymbol } from './AppSymbol'
import { UiTokens } from '../common/Theme'

@Component
export struct QuickAddButton {
  @Prop amount: number = 250
  @Prop icon: string = 'water'
  @Prop primaryColor: string = '#007AFF'
  @Prop cardColor: string = '#FFFFFF'
  @Prop textColor: string = '#1D1D1F'
  onQuickAdd?: () => void
  onLongPress?: () => void

  @State isPressed: boolean = false

  build() {
    Column({ space: 6 }) {
      AppSymbol({ name: this.icon, symbolSize: 22, color: this.primaryColor })

      Text(`${this.amount}`)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textColor)

      Text('ml')
        .fontSize(12)
        .fontColor(this.textColor)
        .opacity(0.5)
    }
    .width(62)
    .height(82)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.isPressed ? this.primaryColor : this.cardColor)
    .borderRadius(UiTokens.cardRadius)
    .scale({ x: this.isPressed ? 0.98 : 1.0, y: this.isPressed ? 0.98 : 1.0 })
    .animation({ duration: 140, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })
    .onClick(() => {
      this.onQuickAdd?.()
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          this.onLongPress?.()
        })
    )
  }
}
