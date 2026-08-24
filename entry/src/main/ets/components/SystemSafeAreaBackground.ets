import { getThemeColors, ThemeColors } from '../common/Theme'

@Component
export struct SystemSafeAreaBackground {
  @Prop colors: ThemeColors = getThemeColors(false, 'blue')

  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(this.colors.background)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
