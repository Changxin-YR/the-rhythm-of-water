import { Beverage } from '../models/Beverage'
import { withAlpha } from '../common/Theme'
import { AppSymbol } from './AppSymbol'

@Component
export struct BeverageSelector {
  @Prop beverages: Beverage[] = []
  @Prop selectedId: string = 'water'
  @Prop primaryColor: string = '#007AFF'
  @Prop cardColor: string = '#FFFFFF'
  @Prop textColor: string = '#1D1D1F'
  @Prop dividerColor: string = '#C6C6C8'
  onSelect?: (beverage: Beverage) => void

  build() {
    Column({ space: 12 }) {
      Text('选择饮品')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.beverages, (item: Beverage) => {
          Column({ space: 4 }) {
            AppSymbol({ name: item.icon, symbolSize: 26, color: this.primaryColor })

            Text(item.name)
              .fontSize(12)
              .fontColor(this.textColor)
              .maxLines(1)
          }
          .width(74)
          .height(76)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(item.id === this.selectedId ? withAlpha(this.primaryColor, '20') : this.cardColor)
          .borderRadius(16)
          .border({
            width: item.id === this.selectedId ? 2 : 0,
              color: item.id === this.selectedId ? this.primaryColor : this.dividerColor
          })
          .margin(4)
          .onClick(() => {
            this.onSelect?.(item)
          })
        }, (item: Beverage) => item.id)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
  }
}
