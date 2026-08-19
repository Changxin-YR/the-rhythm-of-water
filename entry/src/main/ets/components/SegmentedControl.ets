import { UiTokens } from '../common/Theme'

@Component
export struct SegmentedControl {
  @Prop labels: string[] = []
  @Prop selectedIndex: number = 0
  @Prop primaryColor: string = UiTokens.primaryBlue
  @Prop textSecondary: string = '#8899AA'
  @Prop trackColor: string = '#243447'
  @Prop onPrimaryColor: string = '#FFFFFF'
  onChange?: (index: number) => void

  build() {
    Row() {
      ForEach(this.labels, (label: string, index: number) => {
        Text(label)
          .fontSize(12)
          .fontColor(index === this.selectedIndex ? this.onPrimaryColor : this.textSecondary)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(UiTokens.minimumTouchTargetSize)
          .borderRadius(15)
          .backgroundColor(index === this.selectedIndex ? this.primaryColor : Color.Transparent)
          .onClick(() => this.onChange?.(index))
      }, (label: string) => label)
    }
    .width('100%')
    .height(UiTokens.minimumTouchTargetSize + 4)
    .padding(2)
    .backgroundColor(this.trackColor)
    .borderRadius(17)
  }
}
