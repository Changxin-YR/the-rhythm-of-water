import { UiTokens } from '../common/Theme'

@Component
export struct GlassCard {
  @BuilderParam content: () => void
  @Prop radius: number = UiTokens.cardRadius
  @Prop cardPadding: number = UiTokens.cardPadding
  @Prop cardBackground: string = '#FFFFFF'

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.cardPadding)
    .backgroundColor(this.cardBackground)
    .borderRadius(this.radius)
  }
}
