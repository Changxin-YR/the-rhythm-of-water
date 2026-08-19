import { UiTokens } from '../common/Theme'
import { AppSymbol } from './AppSymbol'

@Component
export struct SettingRow {
  @Prop icon: string = ''
  @Prop title: string = ''
  @Prop value: string = ''
  @Prop showArrow: boolean = true
  @Prop showToggle: boolean = false
  @Prop toggleValue: boolean = false
  onAction?: () => void

  build() {
    Row({ space: 12 }) {
      AppSymbol({ name: this.icon, symbolSize: 20, color: UiTokens.primaryBlue })
        .width(28)

      Text(this.title)
        .fontSize(15)
        .fontColor(UiTokens.textPrimary)
        .layoutWeight(1)

      if (this.value) {
        Text(this.value)
          .fontSize(12)
          .fontColor(UiTokens.textSecondary)
      }

      if (this.showToggle) {
        Toggle({ type: ToggleType.Switch, isOn: this.toggleValue })
          .selectedColor(UiTokens.primaryBlue)
      } else if (this.showArrow) {
        AppSymbol({ name: 'next', symbolSize: 16, color: UiTokens.textSecondary })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .onClick(() => this.onAction?.())
  }
}
