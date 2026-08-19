import { Category } from '../models/Category';
import { Constants } from '../common/Constants';
import { LedgerBreakpoint, ResponsiveUtils } from '../common/ResponsiveUtils';
import { ledgerColor } from '../common/LedgerTheme';
import { AppSymbol } from '../../components/AppSymbol';

class CategoryDataSource implements IDataSource {
  private data: Category[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(categories: Category[]) {
    this.data = categories;
  }

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): Category {
    return this.data[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  update(categories: Category[]): void {
    this.data = categories;
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }
}

@Component
export struct CategoryGrid {
  @Prop @Watch('handleCategoriesChange') categories: Category[];
  @Prop selectedId: string;
  onSelect?: (category: Category) => void;
  @State currentBreakpoint: LedgerBreakpoint = LedgerBreakpoint.COMPACT;
  @StorageProp('ledgerDarkMode') ledgerDarkMode: boolean = false;
  private categoryDataSource: CategoryDataSource = new CategoryDataSource([]);

  aboutToAppear(): void {
    this.categoryDataSource.update(this.categories);
  }

  build() {
    Grid() {
      LazyForEach(this.categoryDataSource, (category: Category) => {
        GridItem() {
          Column() {
            Column() {
              AppSymbol({ name: category.icon, symbolSize: 26, color: this.getTileLabelColor(category) })
            }
            .width(56)
            .height(56)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.getTileBackground(category))
            .borderRadius(18)
            .border({
              width: this.getTileBorderWidth(category),
              color: this.getTileBorderColor(category)
            })

            Text(category.name)
              .fontSize(Constants.FONT_SMALL)
              .fontColor(this.getTileLabelColor(category))
              .fontWeight(this.isSelected(category) ? FontWeight.Medium : FontWeight.Normal)
              .height(18)
              .margin({ top: 6 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .height(94)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .borderRadius(Constants.RADIUS_MD)
          .backgroundColor(this.ledgerDarkMode ? ledgerColor('ledger_surface') : ledgerColor('ledger_surface'))
          .border({
            width: this.isSelected(category) ? 1 : 0,
            color: this.isSelected(category) ? category.color : ledgerColor('ledger_surface')
          })
          .onClick(() => {
            if (this.onSelect) {
              this.onSelect(category);
            }
          })
        }
        .height(94)
      }, (category: Category) => category.id)
    }
    .columnsTemplate(this.getColumnsTemplate())
    .rowsGap(8)
    .columnsGap(8)
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.currentBreakpoint = ResponsiveUtils.fromAreaWidth(newValue.width, (value: number) => this.getUIContext().px2vp(value));
    })
  }

  private handleCategoriesChange(): void {
    this.categoryDataSource.update(this.categories);
  }

  private getColumnsTemplate(): string {
    return new Array(ResponsiveUtils.getCategoryColumns(this.currentBreakpoint)).fill('1fr').join(' ');
  }

  private isSelected(category: Category): boolean {
    return this.selectedId === category.id;
  }

  private getTileBackground(category: Category): string {
    return this.isSelected(category) ? ledgerColor('ledger_category_bg') : ledgerColor('ledger_category_unselected_bg');
  }

  private getTileBorderColor(category: Category): string {
    return this.isSelected(category) ? category.color : ledgerColor('ledger_divider');
  }

  private getTileBorderWidth(category: Category): number {
    return this.isSelected(category) ? 2 : 1;
  }

  private getTileLabelColor(category: Category): string {
    return this.isSelected(category) ? ledgerColor('ledger_ink') : ledgerColor('ledger_muted');
  }
}
