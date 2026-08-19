import { UiTokens } from '../common/Theme'
import { AppSymbol } from './AppSymbol'

export interface NavigationItem {
  label: string
  icon: string
}

@Component
export struct BottomNavigation {
  @Prop selectedIndex: number = 0
  @Prop selectedColor: string = '#007AFF'
  @Prop unselectedColor: string = '#5C5C63'
  @Prop backgroundColor: string = '#FFFFFFF2'
  @Prop cardStrokeColor: string = '#C6C6C8'
  @Prop items: NavigationItem[] = [
    { label: '首页', icon: 'overview' },
    { label: '统计', icon: 'calendar' },
    { label: '成就', icon: 'achievement' },
    { label: '设置', icon: 'settings' }
  ]
  onChange?: (index: number) => void

  build() {
    Row() {
      ForEach(this.items, (item: NavigationItem, index: number) => {
        Column({ space: 4 }) {
          AppSymbol({
            name: item.icon,
            symbolSize: 21,
            color: index === this.selectedIndex ? this.selectedColor : this.unselectedColor
          })
          Text(item.label)
            .fontSize(12)
            .fontColor(index === this.selectedIndex ? this.selectedColor : this.unselectedColor)
        }
        .layoutWeight(1)
        .height(UiTokens.bottomBarHeight)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onChange?.(index))
      }, (item: NavigationItem) => item.label)
    }
    .width('100%')
    .height(UiTokens.bottomBarHeight)
    .backgroundColor(this.backgroundColor)
  }
}
