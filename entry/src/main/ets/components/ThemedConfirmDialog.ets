@Component
export struct ThemedConfirmDialog {
  @Prop title: string = ''
  @Prop message: string = ''
  @Prop confirmText: string = '确认'
  @Prop cancelText: string = '取消'
  @Prop showCancel: boolean = true
  @Prop textColor: string = '#E8F0F8'
  @Prop secondaryTextColor: string = '#8899AA'
  @Prop cardColor: string = '#1B2838'
  @Prop surfaceColor: string = '#243447'
  @Prop dividerColor: string = '#3A4B5C'
  @Prop confirmColor: string = '#FF8A80'
  @Prop onConfirmColor: string = '#FFFFFF'
  onCancel?: () => void
  onConfirm?: () => void

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 16 }) {
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textColor)
          .width('100%')

        Text(this.message)
          .fontSize(15)
          .fontColor(this.secondaryTextColor)
          .lineHeight(22)
          .width('100%')

        Row({ space: 12 }) {
          if (this.showCancel) {
            Button(this.cancelText)
              .layoutWeight(1)
              .height(46)
              .fontSize(16)
              .fontColor(this.textColor)
              .backgroundColor(this.surfaceColor)
              .border({ width: 1, color: this.dividerColor })
              .borderRadius(12)
              .onClick(() => {
                this.onCancel?.()
              })
          }

          Button(this.confirmText)
            .layoutWeight(1)
            .height(46)
            .fontSize(16)
            .fontColor(this.onConfirmColor)
            .backgroundColor(this.confirmColor)
            .borderRadius(12)
            .onClick(() => {
              this.onConfirm?.()
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(24)
      .backgroundColor(this.cardColor)
      .border({ width: 1, color: this.dividerColor })
      .borderRadius(20)
      .shadow({ radius: 20, color: '#00000040', offsetX: 0, offsetY: 8 })
      .margin({ left: 24, right: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#00000088')
  }
}
