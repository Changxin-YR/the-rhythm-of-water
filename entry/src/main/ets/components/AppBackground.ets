@Component
export struct AppBackground {
  @BuilderParam content: () => void
  @Prop backgroundColor: string = '#F2F2F7'

  build() {
    Stack() {
      this.content()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.backgroundColor)
  }
}
