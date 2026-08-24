import { parsePositiveWholeMl } from '../common/WaterReminderRules'
import { UiTokens } from '../common/Theme'

@Component
export struct AmountInputDialog {
  @State inputAmount: string = ''
  @State errorText: string = ''
  @Prop primaryColor: string = '#4FC3F7'
  @Prop textColor: string = '#E8F0F8'
  @Prop cardColor: string = '#1B2838'
  @Prop surfaceColor: string = '#243447'
  @Prop dangerColor: string = '#FF8A80'
  @Prop onPrimaryColor: string = '#FFFFFF'
  onCancel?: () => void
  onConfirm?: (amount: number) => void

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 18 }) {
      Text('自定义输入')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)

      TextInput({ placeholder: '请输入毫升数', text: this.inputAmount })
        .type(InputType.Number)
        .width('100%')
        .height(54)
        .fontSize(18)
        .fontColor(this.textColor)
        .placeholderColor(this.textColor)
        .backgroundColor(this.surfaceColor)
        .border({ width: 1, color: this.primaryColor })
        .borderRadius(16)
        .onChange((value: string) => {
          this.inputAmount = value
          this.errorText = ''
        })

      if (this.errorText) {
        Text(this.errorText)
          .fontSize(12)
          .fontColor(this.dangerColor)
          .width('100%')
      }

      Row({ space: 12 }) {
        // Quick options
        ForEach([100, 200, 350, 500], (amount: number) => {
          Text(`${amount}`)
            .fontSize(13)
            .fontColor(this.onPrimaryColor)
            .width(UiTokens.minimumTouchTargetSize)
            .height(UiTokens.minimumTouchTargetSize)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.primaryColor)
            .borderRadius(14)
            .onClick(() => {
              this.inputAmount = amount.toString()
              this.errorText = ''
            })
        }, (amount: number) => amount.toString())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)

        Row({ space: 16 }) {
          Button('取消')
            .fontSize(16)
            .fontColor(this.textColor)
            .backgroundColor(this.surfaceColor)
            .layoutWeight(1)
            .height(46)
            .borderRadius(23)
            .onClick(() => {
              this.onCancel?.()
            })

          Button('确认')
            .fontSize(16)
            .fontColor(this.onPrimaryColor)
            .backgroundColor(this.primaryColor)
            .layoutWeight(1)
            .height(46)
            .borderRadius(23)
            .onClick(() => {
              const raw = this.inputAmount.trim()
              const amount = parsePositiveWholeMl(raw)
              if (!raw) {
                this.errorText = '请输入饮水量'
              } else if (amount === null && Number(raw) > 5000) {
                this.errorText = '单次饮水量不超过 5000ml'
              } else if (amount === null) {
                this.errorText = '请输入有效的正整数'
              } else {
                this.onConfirm?.(amount)
              }
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(24)
      .backgroundColor(this.cardColor)
      .borderRadius(24)
      .border({ width: 1, color: this.primaryColor })
      .shadow({ radius: 20, color: '#00000026', offsetX: 0, offsetY: 8 })
      .margin({ left: 24, right: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#00000088')
  }
}
